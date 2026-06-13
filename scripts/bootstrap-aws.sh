#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME="${PROJECT_NAME:-cook-with-me}"
ENV_NAME="${ENV_NAME:-dev}"
AWS_REGION="${AWS_REGION:-${AWS_DEFAULT_REGION:-us-east-1}}"
AUTO_APPROVE="${AUTO_APPROVE:-true}"

K8S_NAMESPACE="${K8S_NAMESPACE:-cook-with-me}"
K8S_SECRET_NAME="${K8S_SECRET_NAME:-cook-with-me-backend-secrets}"
SECRET_NAME="${SECRET_NAME:-/${PROJECT_NAME}/${ENV_NAME}/app}"
ENV_FILE="${ENV_FILE:-backend/.env.local}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

TF_BOOTSTRAP_DIR="$ROOT_DIR/terraform/bootstrap"
BOOTSTRAP_BACKEND_FILE="$TF_BOOTSTRAP_DIR/backend.tf"
BOOTSTRAP_TFVARS_FILE="$TF_BOOTSTRAP_DIR/terraform.tfvars"

APT_UPDATED="false"

info() { echo "ℹ️  $*"; }
ok() { echo "✅ $*"; }
warn() { echo "⚠️  $*" >&2; }
fail() { echo "❌ $*" >&2; exit 1; }
has() { command -v "$1" >/dev/null 2>&1; }

section() {
  echo
  echo "============================================================"
  echo "$*"
  echo "============================================================"
}

clean_name() {
  echo "$1" | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9-]/-/g;s/--*/-/g;s/^-//;s/-$//'
}

apt_install() {
  if ! has "$1"; then
    if [ "$APT_UPDATED" = "false" ]; then
      sudo apt-get update -y
      APT_UPDATED="true"
    fi
    sudo apt-get install -y "$2"
  fi
}

install_tools() {
  section "Checking local tools"

  apt_install jq jq
  apt_install curl curl
  apt_install unzip unzip
  apt_install git git
  apt_install wget wget
  apt_install gpg gnupg
  apt_install lsb_release lsb-release

  if ! has aws; then
    info "Installing AWS CLI v2..."
    tmp="$(mktemp -d)"
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "$tmp/aws.zip"
    unzip -q "$tmp/aws.zip" -d "$tmp"
    sudo "$tmp/aws/install" --update
    rm -rf "$tmp"
  fi

  if ! has terraform; then
    info "Installing Terraform..."
    wget -O- https://apt.releases.hashicorp.com/gpg 2>/dev/null \
      | gpg --dearmor \
      | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null

    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
      | sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null

    sudo apt-get update -y
    sudo apt-get install -y terraform
  fi

  if ! has gh; then
    info "Installing GitHub CLI..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg >/dev/null

    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null

    sudo apt-get update -y
    sudo apt-get install -y gh
  fi

  has aws || fail "aws is missing"
  has terraform || fail "terraform is missing"
  has gh || fail "gh is missing"
  has jq || fail "jq is missing"
  has git || fail "git is missing"

  ok "Tools are ready"
}

detect_github_repository() {
  git -C "$ROOT_DIR" remote get-url origin 2>/dev/null \
    | sed -E 's#^https://github.com/##;s#^git@github.com:##;s#\.git$##'
}

detect_existing_github_oidc_provider_arn() {
  aws iam list-open-id-connect-providers \
    --query "OpenIDConnectProviderList[].Arn" \
    --output text 2>/dev/null \
    | tr '\t' '\n' \
    | grep 'oidc-provider/token.actions.githubusercontent.com' \
    | head -n 1 || true
}

ensure_gh_auth() {
  section "Validating GitHub CLI auth"

  if gh auth status >/dev/null 2>&1; then
    ok "GitHub CLI is authenticated"
    return
  fi

  warn "GitHub CLI is not authenticated."
  echo
  echo "Run this command, authenticate, then rerun bootstrap:"
  echo
  echo "  gh auth login"
  echo
  fail "GitHub CLI authentication is required to upload repo variables."
}

validate_github_api() {
  section "Validating GitHub API access"

  local max_attempts=5
  local attempt=1
  local sleep_seconds=3

  while [ "$attempt" -le "$max_attempts" ]; do
    if gh api "repos/$GITHUB_REPOSITORY" >/dev/null 2>&1; then
      ok "GitHub API access is working"
      return 0
    fi

    warn "GitHub API check failed attempt $attempt/$max_attempts"

    if [ "$attempt" -eq "$max_attempts" ]; then
      fail "GitHub API is not reachable or repo access is missing."
    fi

    sleep "$sleep_seconds"
    attempt=$((attempt + 1))
    sleep_seconds=$((sleep_seconds * 2))
  done
}

write_local_env_file() {
  mkdir -p "$ROOT_DIR/backend"

  cat > "$ROOT_DIR/$ENV_FILE" <<ENV
OPENAI_API_KEY='$OPENAI_API_KEY'
DATABASE_URL='$DATABASE_URL'
ENV
}

sync_app_secrets() {
  section "Syncing app secrets"

  local existing_openai=""
  local existing_db=""

  if [ -f "$ROOT_DIR/$ENV_FILE" ]; then
    set -a
    # shellcheck disable=SC1090
    source "$ROOT_DIR/$ENV_FILE"
    set +a

    existing_openai="${OPENAI_API_KEY:-}"
    existing_db="${DATABASE_URL:-}"
  fi

  echo "Enter runtime secrets."
  echo "If a local value already exists, pressing Enter keeps it."
  echo

  if [ -n "$existing_openai" ]; then
    info "Existing local OPENAI_API_KEY found. Press Enter to keep it, or paste a new one."
  else
    info "No local OPENAI_API_KEY found. You must paste one."
  fi
  read -rsp "OPENAI_API_KEY: " input_openai
  echo

  if [ -n "$existing_db" ]; then
    info "Existing local DATABASE_URL found. Press Enter to keep it, or paste a new one."
  else
    info "No local DATABASE_URL found. You must paste one."
  fi
  read -rsp "DATABASE_URL: " input_db
  echo

  OPENAI_API_KEY="${input_openai:-$existing_openai}"
  DATABASE_URL="${input_db:-$existing_db}"

  [ -n "${OPENAI_API_KEY:-}" ] || fail "OPENAI_API_KEY is empty."
  [ -n "${DATABASE_URL:-}" ] || fail "DATABASE_URL is empty."

  if [[ "$DATABASE_URL" == mysql://* ]]; then
    info "Normalizing DATABASE_URL to mysql+pymysql://"
    DATABASE_URL="mysql+pymysql://${DATABASE_URL#mysql://}"
  fi

  write_local_env_file

  local secret_json
  secret_json="$(jq -n \
    --arg openai "$OPENAI_API_KEY" \
    --arg db "$DATABASE_URL" \
    '{OPENAI_API_KEY:$openai,DATABASE_URL:$db}')"

  if aws secretsmanager describe-secret \
    --secret-id "$SECRET_NAME" \
    --region "$AWS_REGION" >/dev/null 2>&1; then

    aws secretsmanager put-secret-value \
      --secret-id "$SECRET_NAME" \
      --secret-string "$secret_json" \
      --region "$AWS_REGION" >/dev/null
  else
    aws secretsmanager create-secret \
      --name "$SECRET_NAME" \
      --description "Cook With Me backend runtime secrets for $ENV_NAME" \
      --secret-string "$secret_json" \
      --region "$AWS_REGION" >/dev/null
  fi

  ok "Secrets synced to AWS Secrets Manager: $SECRET_NAME"

  info "Secret verification without printing secret values:"
  aws secretsmanager get-secret-value \
    --secret-id "$SECRET_NAME" \
    --region "$AWS_REGION" \
    --query SecretString \
    --output text \
    | jq '{
        has_OPENAI_API_KEY: (.OPENAI_API_KEY | type == "string" and length > 0),
        has_DATABASE_URL: (.DATABASE_URL | type == "string" and length > 0),
        openai_key_length: (.OPENAI_API_KEY | length),
        database_url_prefix: (.DATABASE_URL | split(":")[0])
      }'
}

prepare_terraform_backend_bucket() {
  section "Preparing Terraform backend bucket"

  local project_clean env_clean
  project_clean="$(clean_name "$PROJECT_NAME")"
  env_clean="$(clean_name "$ENV_NAME")"

  TF_STATE_BUCKET="${project_clean}-${env_clean}-tfstate-${ACCOUNT_ID}-${AWS_REGION}"
  TF_STATE_KEY="tfstate/${project_clean}/${env_clean}/terraform.tfstate"
  TF_BOOTSTRAP_STATE_KEY="tfstate/${project_clean}/${env_clean}/bootstrap.tfstate"

  if ! aws s3api head-bucket --bucket "$TF_STATE_BUCKET" 2>/dev/null; then
    info "Creating tfstate bucket: $TF_STATE_BUCKET"

    if [ "$AWS_REGION" = "us-east-1" ]; then
      aws s3api create-bucket \
        --bucket "$TF_STATE_BUCKET" \
        --region "$AWS_REGION" >/dev/null
    else
      aws s3api create-bucket \
        --bucket "$TF_STATE_BUCKET" \
        --region "$AWS_REGION" \
        --create-bucket-configuration LocationConstraint="$AWS_REGION" >/dev/null
    fi
  fi

  aws s3api put-public-access-block \
    --bucket "$TF_STATE_BUCKET" \
    --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true >/dev/null

  aws s3api put-bucket-versioning \
    --bucket "$TF_STATE_BUCKET" \
    --versioning-configuration Status=Enabled >/dev/null

  aws s3api put-bucket-encryption \
    --bucket "$TF_STATE_BUCKET" \
    --server-side-encryption-configuration \
    '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' >/dev/null

  ok "Terraform backend bucket ready"
}

write_bootstrap_terraform_files() {
  section "Generating bootstrap Terraform files"

  mkdir -p "$TF_BOOTSTRAP_DIR"

  GITHUB_OWNER="$(echo "$GITHUB_REPOSITORY" | cut -d/ -f1)"
  GITHUB_REPO="$(echo "$GITHUB_REPOSITORY" | cut -d/ -f2)"

  GITHUB_OIDC_PROVIDER_ARN="${GITHUB_OIDC_PROVIDER_ARN:-$(detect_existing_github_oidc_provider_arn)}"

  if [ -n "$GITHUB_OIDC_PROVIDER_ARN" ]; then
    info "Existing GitHub OIDC provider detected:"
    info "$GITHUB_OIDC_PROVIDER_ARN"
    github_oidc_value="\"$GITHUB_OIDC_PROVIDER_ARN\""
  else
    info "No existing GitHub OIDC provider detected. terraform/bootstrap will create one."
    github_oidc_value="null"
  fi

  cat > "$BOOTSTRAP_BACKEND_FILE" <<TF
terraform {
  backend "s3" {
    bucket       = "$TF_STATE_BUCKET"
    key          = "$TF_BOOTSTRAP_STATE_KEY"
    region       = "$AWS_REGION"
    encrypt      = true
    use_lockfile = true
  }
}
TF

  cat > "$BOOTSTRAP_TFVARS_FILE" <<TFVARS
project_name  = "$PROJECT_NAME"
env_name      = "$ENV_NAME"
aws_region    = "$AWS_REGION"

github_owner  = "$GITHUB_OWNER"
github_repo   = "$GITHUB_REPO"
github_branch = "$GITHUB_BRANCH"

github_oidc_provider_arn = $github_oidc_value
TFVARS

  ok "bootstrap backend.tf and terraform.tfvars generated"
}

run_bootstrap_terraform() {
  section "Applying terraform/bootstrap"

  [ -f "$TF_BOOTSTRAP_DIR/main.tf" ] || fail "Missing $TF_BOOTSTRAP_DIR/main.tf"
  [ -f "$TF_BOOTSTRAP_DIR/variables.tf" ] || fail "Missing $TF_BOOTSTRAP_DIR/variables.tf"
  [ -f "$TF_BOOTSTRAP_DIR/outputs.tf" ] || fail "Missing $TF_BOOTSTRAP_DIR/outputs.tf"

  terraform -chdir="$TF_BOOTSTRAP_DIR" init -reconfigure
  terraform -chdir="$TF_BOOTSTRAP_DIR" fmt -recursive
  terraform -chdir="$TF_BOOTSTRAP_DIR" validate

  if [ "$AUTO_APPROVE" = "true" ]; then
    terraform -chdir="$TF_BOOTSTRAP_DIR" apply -auto-approve
  else
    terraform -chdir="$TF_BOOTSTRAP_DIR" plan -out=tfplan
    terraform -chdir="$TF_BOOTSTRAP_DIR" apply tfplan
  fi

  AWS_INFRA_ROLE_ARN="$(
    terraform -chdir="$TF_BOOTSTRAP_DIR" output -raw github_actions_infra_role_arn
  )"

  GITHUB_OIDC_PROVIDER_ARN="$(
    terraform -chdir="$TF_BOOTSTRAP_DIR" output -raw github_oidc_provider_arn
  )"

  ok "terraform/bootstrap applied"
  info "GitHub Actions infra role: $AWS_INFRA_ROLE_ARN"
}

set_github_variable() {
  local name="$1"
  local value="$2"
  local max_attempts=5
  local attempt=1
  local sleep_seconds=3

  while [ "$attempt" -le "$max_attempts" ]; do
    if gh variable set "$name" \
      --repo "$GITHUB_REPOSITORY" \
      --body "$value" >/dev/null; then

      ok "GitHub variable set: $name"
      return 0
    fi

    warn "Failed to set GitHub variable: $name attempt $attempt/$max_attempts"

    if [ "$attempt" -eq "$max_attempts" ]; then
      fail "Could not set GitHub variable after $max_attempts attempts: $name"
    fi

    sleep "$sleep_seconds"
    attempt=$((attempt + 1))
    sleep_seconds=$((sleep_seconds * 2))
  done
}

upload_github_variables() {
  section "Uploading GitHub Actions variables"

  set_github_variable "AWS_REGION" "$AWS_REGION"
  set_github_variable "AWS_INFRA_ROLE_ARN" "$AWS_INFRA_ROLE_ARN"

  set_github_variable "TF_STATE_BUCKET" "$TF_STATE_BUCKET"
  set_github_variable "TF_STATE_KEY" "$TF_STATE_KEY"
  set_github_variable "TF_BOOTSTRAP_STATE_KEY" "$TF_BOOTSTRAP_STATE_KEY"

  set_github_variable "PROJECT_NAME" "$PROJECT_NAME"
  set_github_variable "ENV_NAME" "$ENV_NAME"

  set_github_variable "SECRET_NAME" "$SECRET_NAME"
  set_github_variable "K8S_NAMESPACE" "$K8S_NAMESPACE"
  set_github_variable "K8S_SECRET_NAME" "$K8S_SECRET_NAME"

  ok "GitHub Actions variables uploaded"
}

print_summary() {
  section "Foundation bootstrap completed"

  echo "Project:              $PROJECT_NAME"
  echo "Environment:          $ENV_NAME"
  echo "AWS Account ID:       $ACCOUNT_ID"
  echo "AWS Region:           $AWS_REGION"
  echo "GitHub Repository:    $GITHUB_REPOSITORY"
  echo "GitHub Branch:        $GITHUB_BRANCH"
  echo
  echo "Terraform Backend:"
  echo "  S3 Bucket:          $TF_STATE_BUCKET"
  echo "  App State Key:      $TF_STATE_KEY"
  echo "  Bootstrap State Key:$TF_BOOTSTRAP_STATE_KEY"
  echo "  S3 Lockfile:        enabled"
  echo
  echo "Secrets:"
  echo "  Secrets Manager:    $SECRET_NAME"
  echo
  echo "GitHub OIDC:"
  echo "  Provider ARN:       $GITHUB_OIDC_PROVIDER_ARN"
  echo "  Infra Role ARN:     $AWS_INFRA_ROLE_ARN"
  echo
  echo "Kubernetes conventions:"
  echo "  Namespace:          $K8S_NAMESPACE"
  echo "  Secret:             $K8S_SECRET_NAME"
  echo
  echo "Next step:"
  echo "  Run GitHub Actions workflow: build_start.yml"
}

main() {
  section "Cook With Me Foundation Bootstrap"

  cd "$ROOT_DIR"
  info "Project root: $ROOT_DIR"

  install_tools

  section "Validating AWS identity"

  AWS_IDENTITY_JSON="$(aws sts get-caller-identity --output json --region "$AWS_REGION" 2>/dev/null || true)"
  [ -n "$AWS_IDENTITY_JSON" ] || fail "AWS auth missing. Run aws configure or aws sso login."

  ACCOUNT_ID="$(echo "$AWS_IDENTITY_JSON" | jq -r '.Account')"
  AWS_ARN="$(echo "$AWS_IDENTITY_JSON" | jq -r '.Arn')"

  ok "AWS account detected: $ACCOUNT_ID"
  info "Principal: $AWS_ARN"

  section "Detecting GitHub repository"

  GITHUB_REPOSITORY="${GITHUB_REPOSITORY:-$(detect_github_repository || true)}"
  [ -n "$GITHUB_REPOSITORY" ] || fail "Could not detect GitHub repo. Use GITHUB_REPOSITORY=OWNER/REPO."

  GITHUB_BRANCH="${GITHUB_BRANCH:-$(git -C "$ROOT_DIR" branch --show-current 2>/dev/null || echo main)}"
  GITHUB_BRANCH="${GITHUB_BRANCH:-main}"

  ok "GitHub repo: $GITHUB_REPOSITORY"
  info "GitHub branch: $GITHUB_BRANCH"

  ensure_gh_auth
  validate_github_api
  sync_app_secrets
  prepare_terraform_backend_bucket
  write_bootstrap_terraform_files
  run_bootstrap_terraform
  upload_github_variables
  print_summary

  echo
  ok "Done."
}

main "$@"
