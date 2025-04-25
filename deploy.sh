#!/bin/bash

# Exit on any error
set -e

# Set variables
SERVICE_NAME="open-webui"
REGION="europe-west1"
DOMAIN="croud.com"

echo "Starting deployment process for $SERVICE_NAME in $REGION..."

# 1. Submit build to Cloud Build
echo "Building container with Cloud Build..."
#gcloud builds submit --config=cloudbuild.yaml

# 2. Deploy service using YAML configuration
echo "Deploying service to Cloud Run..."
gcloud run services replace service.yaml --region=$REGION

# 3. Add IAM policy to allow domain users to invoke the service
echo "Setting IAM policy to allow domain users to invoke the service..."
gcloud run services add-iam-policy-binding $SERVICE_NAME \
  --region=$REGION \
  --member=domain:$DOMAIN \
  --role=roles/run.invoker

# 4. Enable IAP for the service
echo "Enabling IAP for Cloud Run service..."
gcloud beta run services update $SERVICE_NAME \
  --region=$REGION \
  --iap

# 5. Set IAP access for domain users
echo "Setting IAP access for domain users..."
gcloud beta iap web add-iam-policy-binding \
  --member=domain:$DOMAIN \
  --role=roles/iap.httpsResourceAccessor \
  --region=$REGION \
  --resource-type=cloud-run \
  --service=$SERVICE_NAME \
  --condition=None \
  --quiet

echo "Deployment completed successfully!"
echo "Service URL: https://$SERVICE_NAME-$(gcloud config get-value project | tr : -).${REGION}.run.app"