using Microsoft.Extensions.Azure;

using ServiceBusWorker;

var builder = Host.CreateApplicationBuilder(args);

//Aspire
builder.AddServiceDefaults();
builder.AddAzureBlobClient("blobs");
builder.AddAzureServiceBusClient("service-bus");

builder.Services.AddHostedService<Worker>();

var host = builder.Build();
host.Run();
