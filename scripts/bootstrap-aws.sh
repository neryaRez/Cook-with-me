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
TF_ENV_DIR="$ROOT_DIR/terraform/environments/$ENV_NAME"
BACKEND_FILE="$TF_ENV_DIR/backend.tf"
TFVARS_FILE="$TF_ENV_DIR/terraform.tfvars"

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

  if ! has kubectl; then
    info "Installing kubectl..."
    tmp="$(mktemp)"
    curl -fsSL "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" -o "$tmp"
    chmod +x "$tmp"
    sudo mv "$tmp" /usr/local/bin/kubectl
  fi

  has aws || fail "aws is missing"
  has terraform || fail "terraform is missing"
  has kubectl || fail "kubectl is missing"
  has jq || fail "jq is missing"

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

  echo "Enter runtime secrets for this runner."
  echo "If a local value already exists, pressing Enter keeps it."
  echo

  if [ -n "$existing_openai" ]; then
    info "Existing local OPENAI_API_KEY found. Press Enter to keep it, or paste a new one."
  else
    info "No local OPENAI_API_KEY found. You must paste one."
  fi
  read -rsp "OPENAI_API_KEY: " input_openai; echo

  if [ -n "$existing_db" ]; then
    info "Existing local DATABASE_URL found. Press Enter to keep it, or paste a new one."
  else
    info "No local DATABASE_URL found. You must paste one."
  fi
  read -rsp "DATABASE_URL: " input_db; echo

  OPENAI_API_KEY="${input_openai:-$existing_openai}"
  DATABASE_URL="${input_db:-$existing_db}"

  [ -n "${OPENAI_API_KEY:-}" ] || fail "OPENAI_API_KEY is empty. Paste a value or create $ENV_FILE first."
  [ -n "${DATABASE_URL:-}" ] || fail "DATABASE_URL is empty. Paste a value or create $ENV_FILE first."

  if [[ "$DATABASE_URL" == mysql://* ]]; then
    info "Normalizing DATABASE_URL to mysql+pymysql://"
    DATABASE_URL="mysql+pymysql://${DATABASE_URL#mysql://}"
  fi

  write_local_env_file

  secret_json="$(jq -n \
    --arg openai "$OPENAI_API_KEY" \
    --arg db "$DATABASE_URL" \
    '{OPENAI_API_KEY:$openai,DATABASE_URL:$db}')"

  if aws secretsmanager describe-secret --secret-id "$SECRET_NAME" --region "$AWS_REGION" >/dev/null 2>&1; then
    aws secretsmanager put-secret-value \
      --secret-id "$SECRET_NAME" \
      --secret-string "$secret_json" \
      --region "$AWS_REGION" >/dev/null
  else
    aws secretsmanager create-secret \
      --name "$SECRET_NAME" \
      --description "Cook With Me backend secrets for $ENV_NAME" \
      --secret-string "$secret_json" \
      --region "$AWS_REGION" >/dev/null
  fi

  ok "Secrets synced to AWS Secrets Manager: $SECRET_NAME"

  info "Secret verification without printing secret values:"
  aws secretsmanager get-secret-value     --secret-id "$SECRET_NAME"     --region "$AWS_REGION"     --query SecretString     --output text     | jq '{
        has_OPENAI_API_KEY: (.OPENAI_API_KEY | type == "string" and length > 0),
        has_DATABASE_URL: (.DATABASE_URL | type == "string" and length > 0),
        openai_key_length: (.OPENAI_API_KEY | length),
        database_url_prefix: (.DATABASE_URL | split(":")[0])
      }'
}

prepare_terraform_backend() {
  section "Preparing Terraform backend"

  local project_clean env_clean
  project_clean="$(clean_name "$PROJECT_NAME")"
  env_clean="$(clean_name "$ENV_NAME")"

  STATE_BUCKET="${project_clean}-${env_clean}-tfstate-${ACCOUNT_ID}-${AWS_REGION}"
  STATE_KEY="tfstate/${project_clean}/${env_clean}/terraform.tfstate"

  if ! aws s3api head-bucket --bucket "$STATE_BUCKET" 2>/dev/null; then
    info "Creating tfstate bucket: $STATE_BUCKET"

    if [ "$AWS_REGION" = "us-east-1" ]; then
      aws s3api create-bucket --bucket "$STATE_BUCKET" --region "$AWS_REGION" >/dev/null
    else
      aws s3api create-bucket \
        --bucket "$STATE_BUCKET" \
        --region "$AWS_REGION" \
        --create-bucket-configuration LocationConstraint="$AWS_REGION" >/dev/null
    fi
  fi

  aws s3api put-public-access-block \
    --bucket "$STATE_BUCKET" \
    --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true >/dev/null

  aws s3api put-bucket-versioning \
    --bucket "$STATE_BUCKET" \
    --versioning-configuration Status=Enabled >/dev/null

  aws s3api put-bucket-encryption \
    --bucket "$STATE_BUCKET" \
    --server-side-encryption-configuration \
    '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' >/dev/null


  mkdir -p "$TF_ENV_DIR"

  cat > "$BACKEND_FILE" <<TF
terraform {
  backend "s3" {
    bucket         = "$STATE_BUCKET"
    key            = "$STATE_KEY"
    region         = "$AWS_REGION"
    encrypt      = true
    use_lockfile = true
  }
}
TF

  ok "Terraform backend ready"
}

write_tfvars() {
  section "Generating terraform.tfvars"

  github_owner="$(echo "$GITHUB_REPOSITORY" | cut -d/ -f1)"
  github_repo="$(echo "$GITHUB_REPOSITORY" | cut -d/ -f2)"

  GITHUB_OIDC_PROVIDER_ARN="${GITHUB_OIDC_PROVIDER_ARN:-$(detect_existing_github_oidc_provider_arn)}"

  if [ -n "$GITHUB_OIDC_PROVIDER_ARN" ]; then
    info "Existing GitHub OIDC provider detected:"
    info "$GITHUB_OIDC_PROVIDER_ARN"
    github_oidc_value="\"$GITHUB_OIDC_PROVIDER_ARN\""
  else
    info "No existing GitHub OIDC provider detected. Terraform will create one."
    github_oidc_value="null"
  fi

  cat > "$TFVARS_FILE" <<TFVARS
project_name  = "$PROJECT_NAME"
env_name      = "$ENV_NAME"
aws_region    = "$AWS_REGION"

github_owner  = "$github_owner"
github_repo   = "$github_repo"
github_branch = "$GITHUB_BRANCH"

github_oidc_provider_arn = $github_oidc_value
TFVARS

  ok "terraform.tfvars generated"
}

run_terraform() {
  section "Running Terraform"

  cd "$TF_ENV_DIR"

  terraform init -reconfigure
  terraform fmt -recursive "$ROOT_DIR/terraform"
  terraform validate

  if [ "$AUTO_APPROVE" = "true" ]; then
    terraform apply -auto-approve
  else
    terraform plan -out=tfplan
    terraform apply tfplan
  fi

  EKS_CLUSTER_NAME="$(terraform output -raw eks_cluster_name)"
  BACKEND_ECR_URL="$(terraform output -json ecr_repository_urls | jq -r '.backend')"
  FRONTEND_ECR_URL="$(terraform output -json ecr_repository_urls | jq -r '.frontend')"
  GITHUB_ACTIONS_ROLE_ARN="$(terraform output -raw github_actions_role_arn 2>/dev/null || true)"

  ok "Terraform completed"
}

update_kubeconfig() {
  section "Updating kubeconfig"

  aws eks update-kubeconfig \
    --name "$EKS_CLUSTER_NAME" \
    --region "$AWS_REGION"

  ok "kubeconfig updated"
}

create_kubernetes_secret() {
  section "Creating Kubernetes Secret"

  kubectl get ns "$K8S_NAMESPACE" >/dev/null 2>&1 || kubectl create ns "$K8S_NAMESPACE"

  secret_string="$(aws secretsmanager get-secret-value \
    --secret-id "$SECRET_NAME" \
    --region "$AWS_REGION" \
    --query SecretString \
    --output text)"

  openai_value="$(echo "$secret_string" | jq -r '.OPENAI_API_KEY')"
  db_value="$(echo "$secret_string" | jq -r '.DATABASE_URL')"

  [ -n "$openai_value" ] && [ "$openai_value" != "null" ] || fail "OPENAI_API_KEY missing in secret"
  [ -n "$db_value" ] && [ "$db_value" != "null" ] || fail "DATABASE_URL missing in secret"

  kubectl -n "$K8S_NAMESPACE" create secret generic "$K8S_SECRET_NAME" \
    --from-literal=OPENAI_API_KEY="$openai_value" \
    --from-literal=DATABASE_URL="$db_value" \
    --dry-run=client -o yaml | kubectl apply -f -

  ok "Kubernetes Secret ready: $K8S_SECRET_NAME"
}

print_summary() {
  section "Bootstrap completed"

  echo "Project:              $PROJECT_NAME"
  echo "Environment:          $ENV_NAME"
  echo "AWS Account ID:       $ACCOUNT_ID"
  echo "AWS Region:           $AWS_REGION"
  echo "GitHub Repository:    $GITHUB_REPOSITORY"
  echo "GitHub Branch:        $GITHUB_BRANCH"
  echo
  echo "Terraform Backend:"
  echo "  S3 Bucket:          $STATE_BUCKET"
  echo "  S3 Lockfile:        enabled"
  echo
  echo "AWS Resources:"
  echo "  EKS Cluster:        $EKS_CLUSTER_NAME"
  echo "  Backend ECR:        $BACKEND_ECR_URL"
  echo "  Frontend ECR:       $FRONTEND_ECR_URL"
  echo "  Secrets Manager:    $SECRET_NAME"
  echo
  echo "Kubernetes:"
  echo "  Namespace:          $K8S_NAMESPACE"
  echo "  Secret:             $K8S_SECRET_NAME"

  if [ -n "${GITHUB_ACTIONS_ROLE_ARN:-}" ]; then
    echo
    echo "GitHub Actions:"
    echo "  OIDC Role ARN:      $GITHUB_ACTIONS_ROLE_ARN"
  fi

  echo
  echo "Next step:"
  echo "  GitHub Actions should build/push Docker images and deploy k8s manifests."
}

main() {
  section "Cook With Me AWS Bootstrap"

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

  sync_app_secrets
  prepare_terraform_backend
  write_tfvars
  run_terraform
  update_kubeconfig
  create_kubernetes_secret
  print_summary

  echo
  ok "Done."
}

main "$@"
