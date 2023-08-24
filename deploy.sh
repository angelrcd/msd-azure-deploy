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