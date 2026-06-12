# Cook With Me - Backend

A minimal Flask API for Cook With Me. It serves recipes and the Robo Chef AI
assistant, and is designed to run with mock data locally and to connect to a
real external MySQL database and OpenAI in production.

## Tech stack

- Python 3.12, Flask, flask-cors
- SQLAlchemy + PyMySQL (for the external MySQL database)
- OpenAI Python SDK

## Running locally

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python run.py
```

The server listens on `http://0.0.0.0:8080` by default (override with `PORT`).

No `.env` file is required to run locally - without `DATABASE_URL` the API
serves in-memory mock recipes, and without `OPENAI_API_KEY` `/api/ai/ask`
returns a mock response. Copy `.env.example` to `.env` and export the values
(or use `python-dotenv`/your shell) if you want to test against a real
database or OpenAI.

## Endpoints

- `GET /health` - service status and which integrations are configured
- `GET /api/recipes` - list recipes
- `GET /api/recipes/<id>` - get a single recipe
- `POST /api/recipes` - create a recipe
- `POST /api/recipes/<id>/comments` - add a comment to a recipe
- `POST /api/ai/ask` - ask Robo Chef a cooking question

All responses are JSON, shaped as `{"data": ...}` on success or
`{"error": "..."}` on failure.

### Test /health

```bash
curl http://localhost:8080/health
```

### Test /api/recipes

```bash
curl http://localhost:8080/api/recipes
curl http://localhost:8080/api/recipes/1
```

### Test /api/ai/ask

```bash
curl -X POST http://localhost:8080/api/ai/ask \
  -H "Content-Type: application/json" \
  -d '{"message": "I have chicken, rice and tomatoes. What can I cook?", "context": {}}'
```

## Docker

```bash
docker build -t cook-with-me-backend .
docker run -p 8080:8080 cook-with-me-backend
```

To run against a real database and OpenAI, pass environment variables at run
time:

```bash
docker run -p 8080:8080 \
  -e DATABASE_URL="mysql+pymysql://user:password@host:3306/cookwithme" \
  -e OPENAI_API_KEY="sk-..." \
  cook-with-me-backend
```

## Configuration

All configuration is centralized in `app/config.py` and read from
environment variables:

| Variable       | Purpose                                   | If missing                |
| -------------- | ------------------------------------------ | ------------------------- |
| `DATABASE_URL` | External MySQL connection string          | Uses in-memory mock data   |
| `OPENAI_API_KEY` | OpenAI API key for Robo Chef             | Returns mock AI responses  |
| `PORT`         | Port the server listens on (default 8080) | Defaults to `8080`         |
| `FLASK_ENV`    | `development` or `production`             | Defaults to `production`   |

No secrets are hardcoded or committed - `.env.example` only documents the
expected variable names. In Kubernetes, these same variable names will be
injected via Secrets (e.g. from AWS Secrets Manager) into the container's
environment, so no code changes are needed when moving from mock mode to a
real database and OpenAI integration.

## Project structure

```
backend/
  app/
    __init__.py        Flask app factory
    config.py          Centralized environment configuration
    db.py               SQLAlchemy engine/session for the external MySQL DB
    routes/
      health.py         GET /health
      recipes.py         Recipe + comment endpoints (mock data for now)
      ai.py               POST /api/ai/ask (Robo Chef)
    services/
      openai_service.py  OpenAI integration with mock fallback
  run.py                Entry point - runs the Flask app on 0.0.0.0
  requirements.txt
  Dockerfile
  .dockerignore
  .env.example
```
