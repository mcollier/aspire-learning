var builder = DistributedApplication.CreateBuilder(args);

// Get the Service Bus queue name and use as an environment variable to the worker.
string queueName = builder.Configuration["Parameters:service-bus-queue-name"]
    ?? throw new InvalidOperationException("service-bus-queue-name is not defined");

// Get the Azure Tenant ID and use as an environment variable to the worker.
// Needed for Service Bus client using DefaultAzureCredential when using Azure subscription and a secondary tenant.
string tenantId = builder.Configuration["Parameters:AZURE_TENANT_ID"]
    ?? throw new InvalidOperationException("AZURE_TENANT_ID is not defined");

string deploymentName = builder.Configuration["Parameters:openai-deployment-name"]
    ?? throw new InvalidOperationException("openai-deployment-name is not defined");

// builder.AddAzureStorage("storage").RunAsEmulator();

// var blobs = builder.ExecutionContext.IsPublishMode
//     ? builder.AddAzureStorage("storage").AddBlobs("blobs")
//     : builder.AddConnectionString("blobs");

// Get reference to existing Blob storage endpoint.
var blobs = builder.AddConnectionString("blobs");

// Get reference to existing Service Bus namespace.
var serviceBus = builder.AddConnectionString("service-bus");

// Get a reference to Azure OpenAI endpoint.
var openAI = builder.AddConnectionString("openai");

builder.AddProject<Projects.MyWebApplication>("web-app")
    .WithExternalHttpEndpoints()
    .WithReference(serviceBus)
    .WithReference(openAI)
    .WithEnvironment("AZURE_SERVICE_BUS_QUEUE_NAME", queueName);

builder.AddProject<Projects.ServiceBusWorker>("service-bus-worker")
    .WithReference(blobs)
    .WithReference(serviceBus)
    .WithReference(openAI)
    .WithEnvironment("AZURE_SERVICE_BUS_QUEUE_NAME", queueName)
    .WithEnvironment("AZURE_OPENAI_DEPLOYMENT_NAME", deploymentName)
    .WithEnvironment("AZURE_TENANT_ID", tenantId);


builder.Build().Run();