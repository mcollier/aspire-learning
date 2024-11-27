# aspire-learning

## Aspire Host configuration

Set the following in the *appsettings.Development.json* file:

```json
{
  "Parameters": {
    "service-bus-queue-name": "YOUR-SERVICE-BUS-QUEUE-NAME",
    "AZURE_TENANT_ID": "YOUR-ENTRAID-TENANT-ID"
  },
  "ConnectionStrings": {
    "blobs": "YOUR-AZURE-STORAGE-BLOB-ENDPOINT (e.g., https://contoso.blob.core.windows.net/)",
    "service-bus":"YOUR-FULLY-QUALIFIED-SERVICE-BUS-NAMESPACE (e.g., contoso.servicebus.windows.net)"
  },
  "Azure":{
    "CredentialSource": "AzureCli"
  }
}

```
