using System.Text;
using Azure.Identity;
using Azure.Messaging.ServiceBus;
using Azure.Storage.Blobs;
using OpenAI;
using OpenAI.Chat;

namespace ServiceBusWorker
{
    public class Worker(ILogger<Worker> logger,
                        BlobServiceClient blobServiceClient,
                        ServiceBusClient _serviceBusClient,
                        OpenAIClient openAIClient,
                        IConfiguration configuration) : BackgroundService
    {
        private readonly ILogger<Worker> _logger = logger;
        private readonly ServiceBusClient _client = _serviceBusClient;
        private readonly BlobServiceClient _blobServiceClient = blobServiceClient;
        private readonly OpenAIClient _openAIClient = openAIClient;
        private ServiceBusProcessor _processor = null!; // Initialize with null-forgiving operator
        private readonly IConfiguration _configuration = configuration;

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            string queueName = _configuration["AZURE_SERVICE_BUS_QUEUE_NAME"] ?? throw new InvalidOperationException("Queue name is not configured.");

            _processor = _client.CreateProcessor(queueName, new ServiceBusProcessorOptions());
            _processor.ProcessMessageAsync += MessageHandler;
            _processor.ProcessErrorAsync += ErrorHandler;

            await _processor.StartProcessingAsync(stoppingToken);

            while (!stoppingToken.IsCancellationRequested)
            {
                if (_logger.IsEnabled(LogLevel.Information))
                {
                    _logger.LogInformation("Worker running at: {time}", DateTimeOffset.Now);
                }
                await Task.Delay(1000, stoppingToken);
            }

            await _processor.StopProcessingAsync(stoppingToken);
        }

        private Task ErrorHandler(ProcessErrorEventArgs args)
        {
            _logger.LogError(args.Exception, "Message handler encountered an exception");
            return Task.CompletedTask;
        }

        private async Task MessageHandler(ProcessMessageEventArgs args)
        {
            // TODO: Do some code cleanup!!

            string body = args.Message.Body.ToString();
            _logger.LogInformation($"Received message: {body}");

            // Create a unique name for the new blob
            string blobName = $"widget-{Guid.NewGuid()}.txt";

            // Get a reference to a container
            var containerClient = _blobServiceClient.GetBlobContainerClient("widgets");

            // Ensure the container exists
            await containerClient.CreateIfNotExistsAsync();

            // Get a reference to the blob.
            var blobClient = containerClient.GetBlobClient(blobName);

            // Upload the message body to the blob
            using (var stream = new MemoryStream(Encoding.UTF8.GetBytes(body)))
            {
                await blobClient.UploadAsync(stream, true);
            }

            string deploymentName = _configuration["AZURE_OPENAI_DEPLOYMENT_NAME"] ?? throw new InvalidOperationException("Deployment name is not configured.");

            ChatClient chatClient = _openAIClient.GetChatClient(deploymentName);
            ChatCompletion completion = await chatClient.CompleteChatAsync([
                new SystemChatMessage("You're a helpful assistant that talks like a pirate."),
                new UserChatMessage(body)
                // new UserChatMessage("What's your favorite color?")
            ]);

            _logger.LogInformation($"Role: {completion.Role}. Chat response: {completion.Content[0].Text}");

            // Complete the message. Messages are deleted from the queue.
            await args.CompleteMessageAsync(args.Message);
        }

        public override async Task StopAsync(CancellationToken stoppingToken)
        {
            await _processor.CloseAsync(stoppingToken);
            await base.StopAsync(stoppingToken);
        }
    }
}
