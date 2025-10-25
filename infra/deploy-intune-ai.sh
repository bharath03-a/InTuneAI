#!/bin/bash
set -e

export GOOGLE_CLOUD_PROJECT="data-engineering-ai-472818"
export GOOGLE_CLOUD_LOCATION="us-central1"
export GOOGLE_GENAI_USE_VERTEXAI="false"

check_dependencies() {
    command -v gcloud &> /dev/null || { echo "Install gcloud"; exit 1; }
    command -v pulumi &> /dev/null || { echo "Install pulumi"; exit 1; }
}

authenticate_gcp() {
    gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q . || \
        gcloud auth application-default login
    gcloud config set project $GOOGLE_CLOUD_PROJECT
}

build_and_push_image() {
    cd ../services
    gcloud builds submit --tag us-central1-docker.pkg.dev/$GOOGLE_CLOUD_PROJECT/cloud-run-ai/intuneai-api:latest .
    cd ../infra
}

deploy_with_pulumi() {
    pip install -r requirements.txt
    [ ! -f "Pulumi.dev.yaml" ] && pulumi stack init dev || true

    pulumi config set gcp:project $GOOGLE_CLOUD_PROJECT
    pulumi config set project $GOOGLE_CLOUD_PROJECT
    pulumi config set location $GOOGLE_CLOUD_LOCATION
    pulumi config set use_vertex_ai $GOOGLE_GENAI_USE_VERTEXAI

    pulumi up --yes
    echo "Service URL: $(pulumi stack output service_url)"
}

check_dependencies
authenticate_gcp
build_and_push_image
deploy_with_pulumi
