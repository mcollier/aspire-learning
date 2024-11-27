using System.Text;
using Azure.Identity;
using Azure.Messaging.ServiceBus;
using Azure.Storage.Blobs;

namespace ServiceBusWorker
{
    public class Worker(ILogger<Worker> logger,
                        BlobServiceClient blobServiceClient,
                        ServiceBusClient _serviceBusClient,
                        IConfiguration configuration) : BackgroundService
    {
        private readonly ILogger<Worker> _logger = logger;
        private readonly ServiceBusClient _client = _serviceBusClient;
        private readonly BlobServiceClient _blobServiceClient = blobServiceClient;
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
