#!/bin/bash

APPLICATION_NAME="mcollier-aspire-learning-github-workflow"
GITHUB_REPO="mcollier/aspire-learning"

echo "Please be sure you're logged into the Azure CLI and GitHub CLI!!"

# Check if the Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "Azure CLI is not installed. Please install it before running this script."
    exit 1
fi

# Check if the GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "GitHub CLI is not installed. Please install it before running this script."
    exit 1
fi

# Check if the user is logged into the Azure CLI
azAccount=$(az account show --query id -o tsv)
if [ -z "$azAccount" ]; then
    echo "Please log into the Azure CLI before running this script."
    exit 1
fi

# Check if the user is logged into the GitHub CLI
ghAuthStatus=$(gh auth status 2>&1)
if echo "$ghAuthStatus" | grep -q "not logged in"; then
    echo "$ghAuthStatus"
    echo "Please log into the GitHub CLI before running this script."
    exit 1
fi

AZURE_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
AZURE_TENANT_ID=$(az account show --query tenantId -o tsv)

echo "Using AZURE_SUBSCRIPTION_ID $AZURE_SUBSCRIPTION_ID"
echo "Using AZURE_TENANT_ID $AZURE_TENANT_ID"

# Check if the EntraID application already exists
APP_ID=$(az ad app list --filter "displayName eq '${APPLICATION_NAME}'" --query "[0].appId" -o tsv)
if [ -n "$APP_ID" ]; then
    echo "An application with the name ${APPLICATION_NAME} already exists with APP_ID $APP_ID."
else
    echo "No existing application found with the name ${APPLICATION_NAME}. Proceeding to create a new one."

    # Create the EntraID application
    echo "Creating the EntraID application."
    APP_ID=$(az ad app create --display-name "${APPLICATION_NAME}" --query appId -o tsv)
fi


sleep 5
echo "Using APP_ID $APP_ID"

APPLICATION_OBJECT_ID=$(az ad app show --id "$APP_ID" --query id -o tsv)
echo "Using APPLICATION_OBJECT_ID $APPLICATION_OBJECT_ID"

# Check if the service principal already exists
# SERVICE_PRINCIPAL_ID=$(az ad sp list --filter "appId eq '${APP_ID}'" --query "[0].id" -o tsv)
# if [ -n "$SERVICE_PRINCIPAL_ID" ]; then
#     echo "A service principal for the application already exists with SERVICE_PRINCIPAL_ID $SERVICE_PRINCIPAL_ID."
# else
    # Create a service principal for the EntraID application
    echo "Creating a service principal for the EntraID application."
    SERVICE_PRINCIPAL_ID=$(az ad sp create --id "$APP_ID" --query id -o tsv)
# fi

sleep 5
echo "Using SERVICE_PRINCIPAL_ID $SERVICE_PRINCIPAL_ID"

echo "Creating role assignments for the service principal."
az role assignment create \
    --role Contributor \
    --subscription "$AZURE_SUBSCRIPTION_ID" \
    --assignee-object-id "$SERVICE_PRINCIPAL_ID" \
    --assignee-principal-type ServicePrincipal \
    --scope /subscriptions/"$AZURE_SUBSCRIPTION_ID"

# 7f951dda-4ed3-4680-a7ca-43fe172d538d - AcrPull
# b7e6dc6d-f1e8-4753-8033-0f276bb0955b - Storage Blob Data Owner
# 4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0 - Azure Service Bus Data Receiver
# 69a216fc-b8fb-44d8-bc22-1f3c2cd27a39 - Azure Service Bus Data Sender
# 5e0bd9bd-7b93-4f28-af87-19fc36ad61bd - Cognitive Services OpenAI User
# Assign to 'Role Based Access Control Administrator' role
az role assignment create \
    --role "Role Based Access Control Administrator" \
    --subscription "$AZURE_SUBSCRIPTION_ID" \
    --assignee-object-id "$SERVICE_PRINCIPAL_ID" \
    --assignee-principal-type ServicePrincipal \
    --scope /subscriptions/"$AZURE_SUBSCRIPTION_ID" \
    --condition "((!(ActionMatches{'Microsoft.Authorization/roleAssignments/write'})) OR (@Request[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {7f951dda-4ed3-4680-a7ca-43fe172d538d, b7e6dc6d-f1e8-4753-8033-0f276bb0955b, 4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0, 69a216fc-b8fb-44d8-bc22-1f3c2cd27a39})) AND ((!(ActionMatches{'Microsoft.Authorization/roleAssignments/delete'})) OR (@Resource[Microsoft.Authorization/roleAssignments:RoleDefinitionId] ForAnyOfAnyValues:GuidEquals {7f951dda-4ed3-4680-a7ca-43fe172d538d, b7e6dc6d-f1e8-4753-8033-0f276bb0955b, 4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0, 69a216fc-b8fb-44d8-bc22-1f3c2cd27a39}))"

# TODO: Add logic to set role assignment conditions (assign specific roles).  Test the above more!!

# Create the federated OpenID Connect identity credential
echo "Creating the federated OpenID Connect identity credential."
az rest \
    --method POST \
    --uri "https://graph.microsoft.com/beta/applications/${APPLICATION_OBJECT_ID}/federatedIdentityCredentials" \
    --body "{'name':'refpathfic', 'issuer':'https://token.actions.githubusercontent.com', 'subject':'repo:${GITHUB_REPO}:ref:refs/heads/main', 'description':'main', 'audiences':['api://AzureADTokenExchange']}"

az rest \
    --method POST \
    --uri "https://graph.microsoft.com/beta/applications/${APPLICATION_OBJECT_ID}/federatedIdentityCredentials" \
    --body "{'name':'prfic', 'issuer':'https://token.actions.githubusercontent.com', 'subject':'repo:${GITHUB_REPO}:pull_request', 'description':'pull request', 'audiences':['api://AzureADTokenExchange']}"

echo "Creating GitHub repository secrets"
gh secret set AZURE_CLIENT_ID --body "$APP_ID" --app actions --repo "$GITHUB_REPO"
gh secret set AZURE_SUBSCRIPTION_ID --body "$AZURE_SUBSCRIPTION_ID" --app actions --repo "$GITHUB_REPO"
gh secret set AZURE_TENANT_ID --body "$AZURE_TENANT_ID" --app actions --repo "$GITHUB_REPO"

echo "GitHub $GITHUB_REPO secrets"
gh secret list --repo "$GITHUB_REPO"

echo "Done!"