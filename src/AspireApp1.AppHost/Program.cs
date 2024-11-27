var builder = DistributedApplication.CreateBuilder(args);

// Get the Service Bus queue name and use an an environment variable to the worker.
string queueName = builder.Configuration["Parameters:service-bus-queue-name"] ?? throw new InvalidOperationException("service-bus-queue-name is not defined");

// Get the Azure Tenant ID and use an an environment variable to the worker.
// Needed for Service Bus client using DefaultAzureCredential when using Azure subscription and a secondary tenant.
string tenantId = builder.Configuration["Parameters:AZURE_TENANT_ID"] ?? throw new InvalidOperationException("AZURE_TENANT_ID is not defined");


// Get reference to existing Blob storage endpoint.
var blobs = builder.AddConnectionString("blobs");

// Get reference to existing Service Bus namespace.
var serviceBus = builder.AddConnectionString("service-bus");

builder.AddProject<Projects.WebApplication1>("WebApplication1");

builder.AddProject<Projects.ServiceBusWorker>("ServiceBusWorker")
    .WithReference(blobs)
    .WithReference(serviceBus)
    .WithEnvironment("AZURE_SERVICE_BUS_QUEUE_NAME", queueName)
    .WithEnvironment("AZURE_TENANT_ID", tenantId);


builder.Build().Run();
