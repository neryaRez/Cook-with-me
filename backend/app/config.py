"""Centralized runtime configuration.

All configuration comes from environment variables so that, in Kubernetes,
values can be injected via ConfigMaps and Secrets without any code changes.
"""

import os

DATABASE_URL = os.environ.get("DATABASE_URL")
OPENAI_API_KEY = os.environ.get("OPENAI_API_KEY")
PORT = int(os.environ.get("PORT", "8080"))
FLASK_ENV = os.environ.get("FLASK_ENV", "production")

# Convenience flags used to switch between mock data and real integrations.
USE_DB = bool(DATABASE_URL)
USE_OPENAI = bool(OPENAI_API_KEY)
