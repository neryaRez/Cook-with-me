# Cook With Me

Production-style recipe app built with **React**, **Flask**, **MySQL**, **OpenAI**, **Docker**, **Terraform**, **Kubernetes**, **AWS EKS**, and **GitHub Actions CI/CD**.

The project demonstrates a practical cloud-native workflow: frontend, backend, database persistence, AI integration, containers, infrastructure as code, Kubernetes deployment, runtime secrets, and secure CI/CD with AWS OIDC.

## Quick Start

### 1. Prerequisites

- AWS account and GitHub repository
- AWS CLI configured locally
- Terraform, Docker, GitHub CLI (`gh`), `kubectl`
- MySQL connection URL
- OpenAI API key

### 2. Get `DATABASE_URL`

The backend expects:

```text
mysql+pymysql://USER:PASSWORD@HOST:PORT/DATABASE
```

Use Railway, Aiven, AWS RDS, PlanetScale, or any MySQL-compatible provider. The DB must be reachable from AWS EKS.

### 3. Get `OPENAI_API_KEY`

Create an OpenAI Platform API key and keep it private. Do not commit API keys or database credentials to Git.

### 4. Run Foundation Setup

```bash
./scripts/setup-foundation.sh
```

The script prepares Terraform remote state, GitHub Actions AWS OIDC role, required GitHub repository variables, AWS Secrets Manager location, and base AWS resources needed before CI/CD deploys.

Verify these GitHub repository variables exist:

```text
AWS_REGION
AWS_INFRA_ROLE_ARN
TF_STATE_BUCKET
TF_STATE_KEY
PROJECT_NAME
ENV_NAME
K8S_NAMESPACE
K8S_SECRET_NAME
SECRET_NAME
```

### 5. Store Runtime Secrets

Expected AWS Secrets Manager path:

```text
/cook-with-me/dev/app
```

Expected JSON:

```json
{"OPENAI_API_KEY":"sk-...","DATABASE_URL":"mysql+pymysql://user:password@host:3306/database"}
```

Create secret:

```bash
aws secretsmanager create-secret   --name "/cook-with-me/dev/app"   --secret-string '{"OPENAI_API_KEY":"sk-your-key","DATABASE_URL":"mysql+pymysql://user:password@host:3306/database"}'   --region us-east-1
```

Update secret:

```bash
aws secretsmanager put-secret-value   --secret-id "/cook-with-me/dev/app"   --secret-string '{"OPENAI_API_KEY":"sk-your-key","DATABASE_URL":"mysql+pymysql://user:password@host:3306/database"}'   --region us-east-1
```

### 6. Run First Deployment

```text
Repository -> Actions -> Build Start - Provision and First Deploy -> Run workflow
```

`Build Start` should be manual only:

```yaml
on:
  workflow_dispatch:
```

It runs Terraform, builds backend/frontend images, pushes to ECR, syncs secrets into Kubernetes, applies manifests, waits for rollout, and prints the public Load Balancer URL.

### 7. Verify Deployment

```bash
BASE="http://your-load-balancer-hostname"

curl -I "$BASE/"
curl -s "$BASE/backend/api/recipes"

curl -i -X POST "$BASE/backend/api/ai/ask"   -H "Content-Type: application/json"   -d '{"message":"Give me a quick dinner idea with salmon, rice and garlic"}'
```

Expected: frontend returns `200`, recipes return JSON, and Robo Chef returns an AI answer.

### 8. Regular Updates

```bash
git add .
git commit -m "your change"
git push
```

The `Update` workflow detects changes in `backend/**`, `frontend/**`, and `k8s/**`, then rebuilds and redeploys only the relevant components.

## Architecture

```text
User Browser
    |
AWS Load Balancer
    |
Frontend Service -> Nginx + React Pod
    |
    | /backend/api/*
Backend Service -> Flask + Gunicorn Pod
    |
    +--> MySQL Database
    +--> OpenAI API
```

The frontend is exposed through a Kubernetes `Service` of type `LoadBalancer`, which provisions an AWS Load Balancer. The backend remains internal and is reached through the frontend Nginx reverse proxy.

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | React, Vite, Nginx |
| Backend | Python, Flask, Gunicorn, SQLAlchemy |
| Database | MySQL, PyMySQL |
| AI | OpenAI API |
| Cloud | AWS EKS, ECR, Secrets Manager, S3, IAM |
| DevOps | Docker, Kubernetes, Terraform, GitHub Actions, AWS OIDC |

## Application Layers

### Frontend

React + Vite app served by Nginx. Production build receives:

```bash
VITE_API_BASE_URL=/backend
```

Nginx serves static files and proxies `/backend/*` to the internal Flask service.

### Backend

Flask REST API running with Gunicorn. Handles recipe routes, SQLAlchemy DB access, Robo Chef OpenAI calls, and runtime config.

Required runtime variables:

```text
DATABASE_URL
OPENAI_API_KEY
```

### API

```http
GET    /backend/api/recipes
POST   /backend/api/recipes
DELETE /backend/api/recipes/:id
POST   /backend/api/ai/ask
```

## DevOps

Terraform provisions VPC/networking, EKS, ECR, IAM/OIDC, S3 backend for state, and AWS Secrets Manager integration.

Kubernetes manifests live under `k8s/`.

`Build Start` is the manual first-deploy workflow.

`Update` is the push-based smart deployment workflow:

```text
Backend changed  -> build backend image and deploy backend
Frontend changed -> build frontend image and deploy frontend
K8s changed      -> apply Kubernetes manifests
```

## Security

- No static AWS credentials in GitHub
- GitHub Actions uses AWS OIDC
- Secrets are stored in AWS Secrets Manager
- Secrets are synced into Kubernetes at deployment time
- Docker images do not contain secret values
- Backend is internal to the cluster
- Public exposure is limited to the frontend Load Balancer
- Terraform state is stored remotely in S3

## Local Development

Backend:

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
export DATABASE_URL="mysql+pymysql://user:password@host:3306/database"
export OPENAI_API_KEY="sk-..."
python run.py
```

Frontend:

```bash
cd frontend
npm install
npm run dev
```

With local backend:

```bash
VITE_API_BASE_URL=http://localhost:8080 npm run dev
```

## Docker Build

```bash
docker build -t cook-with-me-backend ./backend

docker build   --build-arg VITE_API_BASE_URL=/backend   -t cook-with-me-frontend   ./frontend
```

## Current Status

Implemented: React frontend, Flask backend, MySQL persistence, recipe create/delete flow, Robo Chef OpenAI integration, Dockerized services, ECR, EKS, Terraform, GitHub Actions OIDC, smart update workflow, and AWS Secrets Manager integration.

## Why This Project Matters

Cook With Me demonstrates practical readiness for DevOps, Cloud, Platform, and Full-Stack roles by combining Terraform, Docker, Kubernetes, AWS, GitHub Actions, secure secrets management, external database integration, and AI API integration.

## Author
Built by **Nerya Rez**.