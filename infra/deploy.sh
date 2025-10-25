#!/bin/bash

# InTuneAI Cloud Run Deployment Script
# This script deploys the InTuneAI API to Google Cloud Run using Pulumi

set -e  # Exit on any error

echo "🚀 Starting InTuneAI Cloud Run Deployment..."

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

    if ! command -v docker &> /dev/null; then
        echo "❌ Docker not found. Please install it first:"
        echo "   https://docs.docker.com/get-docker/"
        exit 1
    fi

    echo "✅ All dependencies found"
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
    gcloud config set project data-engineering-ai-472818
    echo "✅ Project set to data-engineering-ai-472818"
}

# Build and push Docker image
build_and_push_image() {
    echo "🐳 Building and pushing Docker image..."

    # Navigate to services directory
    cd ../services

    # Ensure buildx is available and a builder exists
    if ! docker buildx version >/dev/null 2>&1; then
        echo "❌ Docker Buildx is required. Please update Docker Desktop/Engine."
        exit 1
    fi

    # Create and use a dedicated builder if none exists
    if ! docker buildx inspect intuneai-builder >/dev/null 2>&1; then
        docker buildx create --name intuneai-builder --use >/dev/null
    else
        docker buildx use intuneai-builder >/dev/null
    fi

    # Build the Docker image for linux/amd64 to avoid exec format errors on Cloud Run
    echo "Building multi-arch Docker image (linux/amd64): intuneai-api:latest"
    docker buildx build \
        --platform linux/amd64 \
        -t intuneai-api:latest \
        --load \
        .

    # Tag for Google Artifact Registry
    docker tag intuneai-api:latest us-central1-docker.pkg.dev/data-engineering-ai-472818/cloud-run-ai/intuneai-api:latest

    # Push to Google Artifact Registry
    echo "Pushing image to Google Artifact Registry..."
    docker push us-central1-docker.pkg.dev/data-engineering-ai-472818/cloud-run-ai/intuneai-api:latest

    # Navigate back to infra directory
    cd ../infra

    echo "✅ Docker image built and pushed successfully"
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

    # Set the Docker image in Pulumi config
    echo "Setting Docker image configuration..."
    pulumi config set gcp:project data-engineering-ai-472818

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
    echo "=========================================="

    check_dependencies
    authenticate_gcp
    build_and_push_image
    deploy_with_pulumi

    echo ""
    echo "🎉 Deployment completed successfully!"
    echo "Your InTuneAI API is now running on Google Cloud Run"
    echo ""
    echo "Next steps:"
    echo "1. Test your API endpoint"
    echo "2. Monitor logs: gcloud run services logs tail intuneai-service --region=us-central1"
    echo "3. Update service: pulumi up"
    echo "4. Destroy resources: pulumi destroy"
}

# Run main function
main "$@"
