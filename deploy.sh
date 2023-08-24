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
  --parameters repositoryToken=$GITHUB_TOKEN

# Get the last deployment ouput and store it in a variable
DEPLOYMENT_OUTPUT=$(az deployment group show -g mysweetdreamsrg -n devenvironment --query 'properties.outputs')

# Separate many output values in separate variables
FRONTEND_URI=$(echo "$DEPLOYMENT_OUTPUT" | jq -r '.frontendUri' | jq -r '.value')