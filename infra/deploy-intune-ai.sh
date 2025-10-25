#!/bin/bash

# InTuneAI Cloud Run Deployment Script using Pulumi
# This script deploys the InTuneAI API to Google Cloud Run using Pulumi

set -e  # Exit on any error

echo "🚀 Starting InTuneAI Cloud Run Deployment with Pulumi..."

# Configuration
export GOOGLE_CLOUD_PROJECT="data-engineering-ai-472818"
export GOOGLE_CLOUD_LOCATION="us-central1"
export GOOGLE_GENAI_USE_VERTEXAI="false"

# Check if required tools are installed
check_dependencies() {
    echo "📋 Checking dependencies..."

    if ! command -v gcloud &> /dev/null; then
        echo "❌ gcloud CLI not found. Please install it first:"
        echo "   https://cloud.google.com/sdk/docs/install"
        exit 1
    fi

    if ! command -v pulumi &> /dev/null; then
        echo "❌ Pulumi CLI not found. Please install it first:"
        echo "   https://www.pulumi.com/docs/get-started/install/"
        exit 1
    fi

    echo "✅ All dependencies found"
    echo "📝 Using gcloud builds (no local Docker required)"
}

# Authenticate with Google Cloud
authenticate_gcp() {
    echo "🔐 Authenticating with Google Cloud..."

    # Check if already authenticated
    if gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        echo "✅ Already authenticated with Google Cloud"
    else
        echo "Please authenticate with Google Cloud:"
        gcloud auth login
        gcloud auth application-default login
    fi

    # Set the project
    gcloud config set project $GOOGLE_CLOUD_PROJECT
    echo "✅ Project set to $GOOGLE_CLOUD_PROJECT"
}

# Build and push Docker image using gcloud builds
build_and_push_image() {
    echo "🐳 Building Docker image using Google Cloud Build..."

    # Navigate to services directory
    cd ../services

    # Build using gcloud builds (handles architecture automatically)
    echo "Building with gcloud builds..."
    gcloud builds submit \
        --tag us-central1-docker.pkg.dev/$GOOGLE_CLOUD_PROJECT/cloud-run-ai/intuneai-api:latest \
        .

    # Navigate back to infra directory
    cd ../infra

    echo "✅ Docker image built and pushed successfully"
    echo "📝 Note: gcloud builds handles architecture automatically"
}

# Deploy with Pulumi
deploy_with_pulumi() {
    echo "🏗️  Deploying with Pulumi..."

    # Install Python dependencies
    echo "Installing Python dependencies..."
    pip install -r requirements.txt

    # Initialize Pulumi if not already done
    if [ ! -f "Pulumi.dev.yaml" ]; then
        echo "Initializing Pulumi stack..."
        pulumi stack init dev
    fi

    # Set Pulumi configuration
    echo "Setting Pulumi configuration..."
    pulumi config set gcp:project $GOOGLE_CLOUD_PROJECT
    pulumi config set project $GOOGLE_CLOUD_PROJECT
    pulumi config set location $GOOGLE_CLOUD_LOCATION
    pulumi config set use_vertex_ai $GOOGLE_GENAI_USE_VERTEXAI

    # Deploy the infrastructure
    echo "Deploying Cloud Run service..."
    pulumi up --yes

    echo "✅ Deployment completed successfully!"

    # Get the service URL
    SERVICE_URL=$(pulumi stack output service_url)
    echo "🌐 Your service is available at: $SERVICE_URL"
}

# Main deployment function
main() {
    echo "=========================================="
    echo "   InTuneAI Cloud Run Deployment"
    echo "   Using Pulumi Infrastructure as Code"
    echo "=========================================="
    echo "Project: $GOOGLE_CLOUD_PROJECT"
    echo "Location: $GOOGLE_CLOUD_LOCATION"
    echo "Use Vertex AI: $GOOGLE_GENAI_USE_VERTEXAI"
    echo "Target Architecture: linux/amd64 (Cloud Run)"
    echo "=========================================="

    check_dependencies
    authenticate_gcp
    build_and_push_image
    deploy_with_pulumi

    echo ""
    echo "🎉 Deployment completed successfully!"
    echo "Your InTuneAI API is now running on Google Cloud Run"
    echo ""
    echo "Service Configuration:"
    echo "- Memory: 1Gi"
    echo "- CPU: 1"
    echo "- Max Instances: 10"
    echo "- Port: 8080"
    echo "- Unauthenticated access: Enabled"
    echo ""
    echo "Next steps:"
    echo "1. Test your API endpoint"
    echo "2. Monitor logs: gcloud run services logs tail intune-ai-agent --region=$GOOGLE_CLOUD_LOCATION"
    echo "3. Update service: pulumi up"
    echo "4. Destroy resources: pulumi destroy"
}

# Run main function
main "$@"
