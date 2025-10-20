"""A Google Cloud Python Pulumi program for InTuneAI Cloud Run deployment"""

import pulumi
from pulumi_gcp import cloudrun

# Create a Cloud Run service
service = cloudrun.Service(
    "intuneai-service",
    location="us-central1",
    template=cloudrun.ServiceTemplateArgs(
        spec=cloudrun.ServiceTemplateSpecArgs(
            containers=[
                cloudrun.ServiceTemplateSpecContainerArgs(
                    image="us-central1-docker.pkg.dev/data-engineering-ai-472818/cloud-run-ai/intuneai-api:latest",  # Docker image name
                    ports=[
                        cloudrun.ServiceTemplateSpecContainerPortArgs(
                            container_port=8080, name="http1"
                        )
                    ],
                    resources=cloudrun.ServiceTemplateSpecContainerResourcesArgs(
                        limits={"cpu": "1000m", "memory": "512Mi"}
                    ),
                )
            ]
        )
    ),
)

# Allow unauthenticated access to the service
iam_policy = cloudrun.IamPolicy(
    "intuneai-service-policy",
    location=service.location,
    project=service.project,
    service=service.name,
    policy_data=pulumi.Output.all(service.name).apply(
        lambda args: """{
        "bindings": [
            {
                "role": "roles/run.invoker",
                "members": ["allUsers"]
            }
        ]
    }"""
    ),
)

# Export the service URL
pulumi.export("service_url", service.statuses[0].url)
pulumi.export("service_name", service.name)
