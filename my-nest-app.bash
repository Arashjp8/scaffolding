#!/usr/bin/env bash

export HTTP_PROXY='' HTTPS_PROXY=''

# Exit immediately on errors
set -e

log() {
  local type=$1
  local message=$2
  # Color codes
  local RESET="\e[0m"
  local GREEN="\e[32m"
  local YELLOW="\e[33m"
  local CYAN="\e[36m"
  local BLUE="\e[34m"
  local RED="\e[31m"
  echo ""
  case "$type" in
    "INFO") echo -e "${BLUE}[INFO]${RESET} $message" ;;
    "ERROR") echo -e "${RED}[ERROR]${RESET} $message" ;;
    "SUCCESS") echo -e "${GREEN}[SUCCESS]${RESET} $message" ;;
    "WARNING") echo -e "${YELLOW}[WARNING]${RESET} $message" ;;
    *) echo -e "${CYAN}[NOTIF]${RESET} $message" ;;
  esac
  echo "--------------------------------------------------------------------------------"
}

handle_error() {
  log "ERROR" "$1"
  exit 1
}

command_exists() {
  command -v "$1" &>/dev/null
}

cleanup() {
  log "ERROR" "Aborted. Exiting."
  exit 1
}

trap cleanup SIGINT

copy_template() {
  local template_name="$1"
  local destination="$2"

  TEMPLATE_DIR="$HOME/dev/scaffolding/server-side-scaffolding"
  TEMPLATE_FILE="$TEMPLATE_DIR/$template_name"

  if [[ ! -f "$TEMPLATE_FILE" ]]; then
    handle_error "Template $template_name not found in $TEMPLATE_DIR."
  fi

  cp "$TEMPLATE_FILE" "$destination" || handle_error "Failed to copy $template_name to $destination."
  log "SUCCESS" "Copied $template_name to $destination."
}

create_nestjs_project() {
  local project_name="$1"
  log "INFO" "Creating NestJS project: $project_name"

  if ! command_exists "nest"; then
    handle_error "Nest CLI is not installed. Please install it first: npm i -g @nestjs/cli"
  fi

  nest new "$project_name" --package-manager pnpm || handle_error "Failed to create NestJS project."

  cd "$HOME/dev/$project_name" || handle_error "Failed to navigate to project directory."

  if [[ -z "$SKIP_GIT" ]]; then
    setup_git $project_name $VISIBILITY
  fi

  # to use with posting api client
  mkdir api-collection

  if [[ -z "$SKIP_ESLINT" ]]; then
    setup_eslint
  fi

  if [[ -z "$SKIP_PRETTIER" ]]; then
    setup_prettier
  fi

  log "INFO" "Starting initial linting."
  pnpm run lint
  log "SUCCESS" "Done with initial linting."


  log "SUCCESS" "NestJS project $project_name created successfully! 🚀"
}

setup_eslint() {
  log "INFO" "Configuring ESLint..."
  copy_template ".eslintrc.js" "./.eslintrc.js"

  log "INFO" "Installing ESLint dependencies..."
  pnpm add -D \
    "@typescript-eslint/eslint-plugin@^8.0.0" \
    "@typescript-eslint/parser@^8.0.0" \
    "eslint@^8.57.1" \
    "eslint-config-prettier@^9.1.0" \
    "eslint-plugin-prettier@^5.2.1" || handle_error "Failed to install ESLint dependencies."
}

setup_prettier() {
  log "INFO" "Configuring Prettier..."
  copy_template ".prettierrc" "./.prettierrc"
}


setup_git() {
  local project_name="$1"
  local visibility="${2:-public}"

  if git init &>/dev/null; then
    log "SUCCESS" "Local git repository initialized successfully."
  else
    handle_error "Failed to initialize local Git repository. Ensure Git is installed and configured."
  fi

  copy_template ".gitignore" "./.gitignore"

  if gh repo view "$project_name" &>/dev/null; then
    log "WARNING" "GitHub repository '$project_name' already exists on GitHub."
    read -p "Enter a new repository name: " new_project_name
    
    setup_git "$new_project_name" "$visibility"
    return
  fi

  if [[ -z "$SKIP_GIT" ]]; then
    read -p "Do you want to create a GitHub repository for this project? (Y/n): " create_repo
    create_repo="${create_repo:-Y}" # Default to Y if no input
    
    if [[ "$create_repo" =~ ^[Yy]$ ]]; then
      if gh repo create "$project_name" --"$visibility" &>/dev/null; then
        log "SUCCESS" "GitHub repository '$project_name' created successfully as $visibility."
        
        git add .
        git commit -m "[initial] - first commit"
        git branch -M main
        git remote add origin "https://github.com/Arashjp8/${project_name}"
        git push -u origin main

        log "SUCCESS" "GitHub repository linked and initial commit pushed."
      else
        handle_error "Failed to create GitHub repository. Ensure you are authenticated with GitHub CLI."
      fi
    else
      log "INFO" "Skipping GitHub repository creation."
    fi
  fi
}

print_help() {
  echo -e "Usage: $0 [OPTIONS]"

  local help_file="$HOME/dev/scaffolding/server-side-scaffolding/my-server-help.txt"
  cat "$help_file"

  exit 0
}

parse_flags() {
  while [[ "$#" -gt 0 ]]; do
    case $1 in
      --project-name)
        PROJECT_NAME="$2"
        shift 2
        ;;
      --visibility)
        VISIBILITY="$2"
        shift 2
        ;;
      --skip-git)
        SKIP_GIT=true
        shift
        ;;
      --skip-eslint)
        SKIP_ESLINT=true
        shift
        ;;
      --skip-prettier)
        SKIP_PRETTIER=true
        shift
        ;;
      --help)
        print_help
        ;;
      *)
        log "ERROR" "Unknown flag: $1"
        exit 1
        ;;
    esac
  done

  if [[ -z "$PROJECT_NAME" ]]; then
    read -p "Enter project name: " input
    PROJECT_NAME=$(echo "$input" | sed -E "s/([a-z])([A-Z])/\1-\L\2/g" | tr "._ " "-")

    [[ -z "$PROJECT_NAME" ]] && handle_error "Project name cannot be empty."
    echo "$PROJECT_NAME"
  fi
}

prompt_user_input() {
  local prompt_message="$1"
  read -p "$prompt_message" input
  echo "$input"
}

main() {
  parse_flags "$@"

  cd "$HOME/dev"; log "" "Making project in this directory"; pwd; echo ""  || handle_error "Failed to navigate to dev directory."
  
  create_nestjs_project "$PROJECT_NAME"
  log "SUCCESS" "Project $PROJECT_NAME setup complete."
}

main "$@"
