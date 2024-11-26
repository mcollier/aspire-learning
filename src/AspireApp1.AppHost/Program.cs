var builder = DistributedApplication.CreateBuilder(args);

string queueName = builder.Configuration["Parameters:service-bus-queue-name"];
//string serviceBusNamespace = builder.Configuration["Parameters:service-bus-namespace"];
string tenantId = builder.Configuration["Parameters:AZURE_TENANT_ID"];

//var serviceBus = builder.AddConnectionString("serviceBus");
//builder.AddAzureServiceBus("serviceBus-managed-identity");

builder.AddProject<Projects.WebApplication1>("WebApplication1");

builder.AddProject<Projects.ServiceBusWorker>("ServiceBusWorker")
    .WithEnvironment("AZURE_TENANT_ID", tenantId)
    .WithEnvironment("AZURE_SERVICE_BUS_QUEUE_NAME", queueName)
    //.WithEnvironment("AZURE_SERVICE_BUS_NAMESPACE", serviceBusNamespace)
    .WithEnvironment("AZURE_EXPERIMENTAL_ENABLE_ACTIVITY_SOURCE", "true");

builder.Build().Run();
