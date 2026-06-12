"""Robo Chef integration with the OpenAI API.

If OPENAI_API_KEY is not configured, ask_robo_chef() returns a clearly
labeled mock answer so the rest of the app keeps working in local/dev mode.
"""

from openai import OpenAI

from .. import config

_client = OpenAI(api_key=config.OPENAI_API_KEY) if config.USE_OPENAI else None

SYSTEM_PROMPT = (
    "You are Robo Chef, a friendly and concise AI cooking assistant for the "
    "Cook With Me app. Give practical, short answers about recipes, "
    "ingredient substitutions, and cooking techniques."
)


def ask_robo_chef(message, context=None):
    if _client is None:
        return (
            "[Mock Robo Chef] OPENAI_API_KEY is not configured, so this is a "
            f"placeholder response. You asked: \"{message}\". Once an OpenAI "
            "API key is provided, Robo Chef will answer using a real AI model."
        )

    response = _client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": message},
        ],
    )
    return response.choices[0].message.content
