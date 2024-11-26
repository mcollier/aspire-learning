using Azure.Identity;
using Azure.Messaging.ServiceBus;

namespace ServiceBusWorker
{
    public class Worker : BackgroundService
    {
        private readonly ILogger<Worker> _logger;
        private readonly ServiceBusClient _client;
        private ServiceBusProcessor _processor = null!; // Initialize with null-forgiving operator

        public Worker(ILogger<Worker> logger, IConfiguration configuration)
        {
            _logger = logger;
            string serviceBusNamespace = configuration["AZURE_SERVICE_BUS_NAMESPACE"];
            var credentialOptions = new DefaultAzureCredentialOptions {
                TenantId = configuration["AZURE_TENANT_ID"],
            };
            _client = new ServiceBusClient(serviceBusNamespace, new DefaultAzureCredential(credentialOptions));
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _processor = _client.CreateProcessor("widgets", new ServiceBusProcessorOptions());

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
