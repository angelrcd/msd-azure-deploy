# Sets environment variables from .env file
export $(grep -v '^#' .env | xargs)

az login
az group create \
  --name mysweetdreamsrg \
  --location 'westeurope'
az deployment group create \
  --name devenvironment \
  --resource-group mysweetdreamsrg \
  --template-file ./template.json \
  --parameters ./parameters.json \
  --parameters repositoryToken=$GITHUB_TOKEN \
  --parameters dockerRegistryPassword='dckr_pat_dVGfw1Qx5YN3Get1SqgeSyrnR6M'

# Get the last deployment ouput and store it in a variable
DEPLOYMENT_OUTPUT=$(az deployment group show -g mysweetdreamsrg -n devenvironment --query 'properties.outputs')

# Separate many output values in separate variables
FRONTEND_URI=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.frontendUri.value')
STORAGE_ACCOUNT_KEY=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.storageAccountKey.value')
COSMOS_DB_CONNECTION_STRING=$(az cosmosdb keys list --type connection-strings --name msdmongodbarc --resource-group mysweetdreamsrg | jq -r '.connectionStrings[] | select(.keyKind == "Primary").connectionString')

# Create container in storage account and upload default user profile pic
az storage container create --name user-pfp --account-name $STORAGE_ACCOUNT_NAME --public-access blob --account-key $STORAGE_ACCOUNT_KEY
az storage blob upload --account-name $STORAGE_ACCOUNT_NAME --container-name user-pfp --file default.png --account-key $STORAGE_ACCOUNT_KEY --overwrite

# Set App configuration of the backend App Service Web App
az webapp config appsettings set -n msd-api-arc -g mysweetdreamsrg --settings \
PORT=$PORT \
NODE_ENV=$NODE_ENV \
SALT_SEED=$SALT_SEED \
SECRET_OR_PRIVATE_KEY=$SECRET_OR_PRIVATE_KEY \
ALLOW_ORIGIN="https://${FRONTEND_URI}" \
STORAGE_CONNECTION_STRING="DefaultEndpointsProtocol=https;AccountName=${STORAGE_ACCOUNT_NAME};AccountKey=${STORAGE_ACCOUNT_KEY};EndpointSuffix=core.windows.net" \
STORAGE_CONTAINER_NAME="user-pfp" \
MONGO_IP=$COSMOS_DB_CONNECTION_STRING

