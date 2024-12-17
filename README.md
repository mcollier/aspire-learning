# aspire-learning

:warning: This is a self-learning repository. Use at your own risk. :warning:

## Aspire Host configuration

Set the following in the *appsettings.Development.json* file:

```json
{
    "Parameters": {
        "service-bus-queue-name": "widgets",
        "openai-deployment-name": "[YOUR-OPENAI-DEPLOYMENT-NAME]",
        "AZURE_TENANT_ID": "[YOUR-AZURE-TENANT-ID]"
    },
    "ConnectionStrings": {
        "blobs": "https://[YOUR-AZURE-STORAGE-ACCOUNT-NAME].blob.core.windows.net/",
        "service-bus": "[YOUR-AZURE-SERVICE-BUS-NAME].servicebus.windows.net",
        "openai": "https://[YOUR-AZURE-OPENAI-NAME].openai.azure.com/"
    },
    "Azure": {
        "CredentialSource": "AzureCli"
    },
    "Logging": {
        "LogLevel": {
            "Default": "Information",
            "Microsoft.AspNetCore": "Warning"
        }
    }
}

```
