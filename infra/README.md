# InTuneAI Cloud Run Deployment

This directory contains the infrastructure code for deploying the InTuneAI API to Google Cloud Run using Pulumi.

## Overview

The InTuneAI API is deployed as a containerized service on Google Cloud Run, providing:

- Serverless container execution
- Automatic scaling
- Pay-per-use pricing
- Global availability

## Prerequisites

Before deploying, ensure you have the following installed:

1. **Google Cloud CLI** - [Install Guide](https://cloud.google.com/sdk/docs/install)
2. **Pulumi CLI** - [Install Guide](https://www.pulumi.com/docs/get-started/install/)
3. **Docker** - [Install Guide](https://docs.docker.com/get-docker/)
4. **Python 3.12+** - [Install Guide](https://www.python.org/downloads/)

## Quick Deployment

The easiest way to deploy is using the provided deployment script:

```bash
./deploy.sh
```

This script will:

1. Check all dependencies
2. Authenticate with Google Cloud
3. Build and push the Docker image
4. Deploy the Cloud Run service using Pulumi

## Manual Deployment Steps

If you prefer to deploy manually, follow these steps:

### 1. Authenticate with Google Cloud

```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project data-engineering-ai-472818
```

### 2. Build and Push Docker Image

```bash
# Navigate to services directory
cd ../services

# Build the Docker image
docker build -t intuneai-api:latest .

# Tag for Google Artifact Registry
docker tag intuneai-api:latest us-central1-docker.pkg.dev/data-engineering-ai-472818/cloud-run-ai/intuneai-api:latest

# Push to Google Artifact Registry
docker push us-central1-docker.pkg.dev/data-engineering-ai-472818/cloud-run-ai/intuneai-api:latest

# Return to infra directory
cd ../infra
```

### 3. Install Dependencies

```bash
pip install -r requirements.txt
```

### 4. Deploy with Pulumi

```bash
# Initialize Pulumi stack (if not already done)
pulumi stack init dev

# Deploy the infrastructure
pulumi up
```

## Configuration

The deployment uses the following configuration:

- **Project**: `data-engineering-ai-472818`
- **Region**: `us-central1`
- **Container Image**: `us-central1-docker.pkg.dev/data-engineering-ai-472818/cloud-run-ai/intuneai-api:latest`
- **Port**: `8080`
- **CPU**: `1000m` (1 vCPU)
- **Memory**: `512Mi`

## Resources Created

- **Cloud Run Service**: `intuneai-service`
- **IAM Policy**: Allows unauthenticated access to the service

## Outputs

After deployment, you'll get:

- **service_url**: The public URL of your deployed service
- **service_name**: The name of the Cloud Run service

## Monitoring and Management

### View Logs

```bash
gcloud run services logs tail intuneai-service --region=us-central1
```

### Update Service

```bash
pulumi up
```

### Destroy Resources

```bash
pulumi destroy
```

## Project Structure

```
infra/
├── __main__.py          # Pulumi program defining Cloud Run service
├── deploy.sh            # Automated deployment script
├── requirements.txt     # Python dependencies
├── Pulumi.yaml         # Pulumi project configuration
├── Pulumi.dev.yaml     # Development stack configuration
└── README.md           # This file
```

## Troubleshooting

### Common Issues

1. **Authentication Error**

   ```bash
   gcloud auth application-default login
   ```

2. **Docker Push Permission Denied**

   ```bash
   gcloud auth configure-docker
   ```

3. **Pulumi Stack Not Found**
   ```bash
   pulumi stack init dev
   ```

### Getting Help

- [Pulumi Documentation](https://www.pulumi.com/docs/)
- [Google Cloud Run Documentation](https://cloud.google.com/run/docs)
- [Pulumi GCP Provider](https://www.pulumi.com/registry/packages/gcp/)

## Next Steps

After successful deployment:

1. Test your API endpoint
2. Set up monitoring and alerting
3. Configure custom domains if needed
4. Set up CI/CD for automated deployments
