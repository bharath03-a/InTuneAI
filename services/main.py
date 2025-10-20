import os
from typing import Literal

from dotenv import load_dotenv
from fastapi import FastAPI
from google.adk.cli.fast_api import get_fast_api_app
from google.cloud import logging as google_cloud_logging
from pydantic import BaseModel

# Load environment variables from .env file
load_dotenv()

logging_client = google_cloud_logging.Client()
logger = logging_client.logger(__name__)

AGENT_DIR = os.path.dirname(os.path.abspath(__file__))
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Get session service URI from environment variables
session_uri = SESSION_DB_URL = f"sqlite:///{os.path.join(BASE_DIR, 'sessions.db')}"

# Prepare arguments for get_fast_api_app
app_args = {"agents_dir": AGENT_DIR, "web": False, "allow_origins": ["*"]}

# Only include session_service_uri if it's provided
if session_uri:
    app_args["session_service_uri"] = session_uri
else:
    logger.log_text(
        "SESSION_SERVICE_URI not provided. Using in-memory session service instead. "
        "All sessions will be lost when the server restarts.",
        severity="WARNING",
    )

# Create FastAPI app with appropriate arguments
app: FastAPI = get_fast_api_app(**app_args)

app.title = "intune-ai-agent"
app.description = "API for interacting with the Agent intune-ai-agent"


class Feedback(BaseModel):
    """Represents feedback for a conversation."""

    score: int | float
    text: str | None = ""
    invocation_id: str
    log_type: Literal["feedback"] = "feedback"
    service_name: Literal["intune-ai-agent"] = "intune-ai-agent"
    user_id: str = ""


@app.post("/feedback")
def collect_feedback(feedback: Feedback) -> dict[str, str]:
    """Collect and log feedback.

    Args:
        feedback: The feedback data to log

    Returns:
        Success message
    """
    logger.log_struct(feedback.model_dump(), severity="INFO")
    return {"status": "success"}


@app.get("/health")
async def health_check():
    return {"status": "healthy"}


@app.get("/agent-info")
async def agent_info():
    """Provide agent information"""
    from multi_tool_agent.agent import root_agent

    return {
        "agent_name": root_agent.name,
        "description": root_agent.description,
        "model": root_agent.model,
        "tools": [t.__name__ for t in root_agent.tools],
    }


# Main execution
if __name__ == "__main__":
    import os

    import uvicorn

    port = int(os.environ.get("PORT", 8080))
    uvicorn.run(app, host="0.0.0.0", port=port)
