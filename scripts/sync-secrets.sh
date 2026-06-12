#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Cook With Me - Secrets Bootstrap / Sync
#
# Lazy-reviewer friendly:
#   - Installs missing local tools when possible: jq, curl, unzip, aws cli v2
#   - Detects AWS account + region automatically
#   - Always asks the runner for their own:
#       1. OPENAI_API_KEY
#       2. DATABASE_URL
#   - Saves them locally to backend/.env.local
#   - Syncs them into AWS Secrets Manager
#
# Local file is temporary and gitignored:
#   backend/.env.local
# ============================================================

PROJECT_NAME="${PROJECT_NAME:-cook-with-me}"
ENV_NAME="${ENV_NAME:-dev}"
ENV_FILE="${ENV_FILE:-backend/.env.local}"

APT_UPDATED="false"

info() {
  echo "ℹ️  $*"
}

success() {
  echo "✅ $*"
}

warn() {
  echo "⚠️  $*" >&2
}

fail() {
  echo "❌ $*" >&2
  exit 1
}

has_command() {
  command -v "$1" >/dev/null 2>&1
}

require_sudo() {
  if ! has_command sudo; then
    fail "sudo is required to install missing dependencies automatically."
  fi
}

apt_update_once() {
  if [ "$APT_UPDATED" = "false" ]; then
    require_sudo
    info "Updating apt package index..."
    sudo apt-get update -y
    APT_UPDATED="true"
  fi
}

install_apt_package() {
  local package="$1"

  if ! has_command apt-get; then
    fail "Cannot auto-install $package because apt-get was not found. Please install it manually."
  fi

  apt_update_once
  info "Installing missing package: $package"
  sudo apt-get install -y "$package"
}

ensure_command_from_apt() {
  local command_name="$1"
  local package_name="$2"

  if ! has_command "$command_name"; then
    install_apt_package "$package_name"
  fi
}

install_aws_cli_v2() {
  if has_command aws; then
    return
  fi

  warn "AWS CLI was not found. Installing AWS CLI v2..."

  ensure_command_from_apt curl curl
  ensure_command_from_apt unzip unzip

  local tmp_dir
  tmp_dir="$(mktemp -d)"

  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
    -o "$tmp_dir/awscliv2.zip"

  unzip -q "$tmp_dir/awscliv2.zip" -d "$tmp_dir"

  require_sudo
  sudo "$tmp_dir/aws/install" --update

  rm -rf "$tmp_dir"

  if ! has_command aws; then
    fail "AWS CLI installation finished, but aws is still not available in PATH. Open a new terminal and try again."
  fi

  success "AWS CLI v2 installed."
}

escape_single_quotes() {
  printf "%s" "$1" | sed "s/'/'\\\\''/g"
}

write_local_env_file() {
  local openai_escaped
  local db_escaped

  openai_escaped="$(escape_single_quotes "$OPENAI_API_KEY")"
  db_escaped="$(escape_single_quotes "$DATABASE_URL")"

  mkdir -p "$(dirname "$ENV_FILE")"

  cat > "$ENV_FILE" <<ENV
OPENAI_API_KEY='$openai_escaped'
DATABASE_URL='$db_escaped'
ENV
}

info "Checking local dependencies..."

ensure_command_from_apt jq jq
ensure_command_from_apt curl curl
ensure_command_from_apt unzip unzip
install_aws_cli_v2

success "Local dependencies are ready."
echo

if ! AWS_IDENTITY_JSON="$(aws sts get-caller-identity --output json 2>/dev/null)"; then
  fail "AWS CLI is installed but not authenticated.

Run one of these and then run this script again:

  aws configure

or, if using SSO:

  aws sso login

AWS authentication cannot be automated safely because credentials must belong to the runner."
fi

AWS_ACCOUNT_ID="$(echo "$AWS_IDENTITY_JSON" | jq -r '.Account')"
AWS_ARN="$(echo "$AWS_IDENTITY_JSON" | jq -r '.Arn')"

AWS_REGION="${AWS_REGION:-$(aws configure get region || true)}"
AWS_REGION="${AWS_REGION:-us-east-1}"

SECRET_NAME="${SECRET_NAME:-/${PROJECT_NAME}/${ENV_NAME}/app}"

info "Project:        $PROJECT_NAME"
info "Environment:    $ENV_NAME"
info "AWS Account ID: $AWS_ACCOUNT_ID"
info "AWS Region:     $AWS_REGION"
info "AWS Principal:  $AWS_ARN"
info "Secret Name:    $SECRET_NAME"
info "Local env file: $ENV_FILE"
echo

EXISTING_OPENAI_API_KEY=""
EXISTING_DATABASE_URL=""

if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a

  EXISTING_OPENAI_API_KEY="${OPENAI_API_KEY:-}"
  EXISTING_DATABASE_URL="${DATABASE_URL:-}"
fi

echo "This project needs exactly two private runtime values."
echo "They will be saved locally to $ENV_FILE and synced to AWS Secrets Manager."
echo
echo "Required values:"
echo "  1. OPENAI_API_KEY"
echo "  2. DATABASE_URL"
echo

if [ -n "$EXISTING_OPENAI_API_KEY" ]; then
  echo "OPENAI_API_KEY already exists locally."
  echo "Paste a new value, or press Enter to keep the existing local value."
else
  echo "Enter your OpenAI API key."
fi

read -rsp "OPENAI_API_KEY: " INPUT_OPENAI_API_KEY
echo

if [ -n "$INPUT_OPENAI_API_KEY" ]; then
  OPENAI_API_KEY="$INPUT_OPENAI_API_KEY"
else
  OPENAI_API_KEY="$EXISTING_OPENAI_API_KEY"
fi

echo

if [ -n "$EXISTING_DATABASE_URL" ]; then
  echo "DATABASE_URL already exists locally."
  echo "Paste a new value, or press Enter to keep the existing local value."
else
  echo "Enter your external MySQL connection string."
  echo "Example:"
  echo "  mysql://root:password@host:port/railway"
fi

read -rsp "DATABASE_URL: " INPUT_DATABASE_URL
echo

if [ -n "$INPUT_DATABASE_URL" ]; then
  DATABASE_URL="$INPUT_DATABASE_URL"
else
  DATABASE_URL="$EXISTING_DATABASE_URL"
fi

[ -n "${OPENAI_API_KEY:-}" ] || fail "OPENAI_API_KEY is empty."
[ -n "${DATABASE_URL:-}" ] || fail "DATABASE_URL is empty."

if [[ "$DATABASE_URL" == mysql://* ]]; then
  info "Normalizing DATABASE_URL from mysql:// to mysql+pymysql://"
  DATABASE_URL="mysql+pymysql://${DATABASE_URL#mysql://}"
fi

write_local_env_file
success "Local env file updated: $ENV_FILE"
echo

SECRET_JSON="$(jq -n \
  --arg openai "$OPENAI_API_KEY" \
  --arg db "$DATABASE_URL" \
  '{
    OPENAI_API_KEY: $openai,
    DATABASE_URL: $db
  }'
)"

if aws secretsmanager describe-secret \
  --secret-id "$SECRET_NAME" \
  --region "$AWS_REGION" >/dev/null 2>&1; then

  info "Secret exists. Updating secret value..."

  aws secretsmanager put-secret-value \
    --secret-id "$SECRET_NAME" \
    --secret-string "$SECRET_JSON" \
    --region "$AWS_REGION" >/dev/null

else
  info "Secret does not exist. Creating it..."

  aws secretsmanager create-secret \
    --name "$SECRET_NAME" \
    --description "Cook With Me backend secrets for ${ENV_NAME}" \
    --secret-string "$SECRET_JSON" \
    --region "$AWS_REGION" >/dev/null
fi

success "Secrets synced to AWS Secrets Manager."
echo
echo "Secret name:"
echo "  $SECRET_NAME"
echo
echo "Verify without printing secret values:"
echo "  aws secretsmanager describe-secret --secret-id \"$SECRET_NAME\" --region \"$AWS_REGION\""
echo
echo "Local temporary env file:"
echo "  $ENV_FILE"
echo
echo "Later, after Kubernetes secret is created and tested, you can delete it:"
echo "  rm -f $ENV_FILE"
