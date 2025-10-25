"""A Google Cloud Python Pulumi program for InTuneAI Cloud Run deployment"""

import pulumi
from pulumi_gcp import cloudrun

# Get configuration values
config = pulumi.Config()
project_id = config.get("project") or "data-engineering-ai-472818"
location = config.get("location") or "us-central1"
use_vertex_ai = config.get_bool("use_vertex_ai") or False

# Create a Cloud Run service
service = cloudrun.Service(
    "intune-ai-agent",
    location=location,
    template=cloudrun.ServiceTemplateArgs(
        metadata=cloudrun.ServiceTemplateMetadataArgs(
            annotations={
                "autoscaling.knative.dev/maxScale": "10",
                "run.googleapis.com/execution-environment": "gen2",
            }
        ),
        spec=cloudrun.ServiceTemplateSpecArgs(
            containers=[
                cloudrun.ServiceTemplateSpecContainerArgs(
                    image=pulumi.Config().get("image")
                    or "us-central1-docker.pkg.dev/data-engineering-ai-472818/cloud-run-ai/intuneai-api:latest",
                    ports=[
                        cloudrun.ServiceTemplateSpecContainerPortArgs(
                            container_port=8080, name="http1"
                        )
                    ],
                    resources=cloudrun.ServiceTemplateSpecContainerResourcesArgs(
                        limits={"cpu": "1000m", "memory": "1Gi"}
                    ),
                    envs=[
                        cloudrun.ServiceTemplateSpecContainerEnvArgs(
                            name="GOOGLE_CLOUD_PROJECT", value=project_id
                        ),
                        cloudrun.ServiceTemplateSpecContainerEnvArgs(
                            name="GOOGLE_CLOUD_LOCATION", value=location
                        ),
                        cloudrun.ServiceTemplateSpecContainerEnvArgs(
                            name="GOOGLE_GENAI_USE_VERTEXAI",
                            value=str(use_vertex_ai).lower(),
                        ),
                    ],
                )
            ]
        ),
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
