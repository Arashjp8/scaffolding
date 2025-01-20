#!/usr/bin/env bash

export HTTP_PROXY='' HTTPS_PROXY=''

# Exit the script immediately on errors
set -e

handle_error() {
  log "ERROR" "$1"
  exit 1
}

command_exists() {
  command -v "$1" &>/dev/null
}

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

cleanup() {
  log "ERROR" "Aborted. Exiting."
  exit 1
}

trap cleanup SIGINT

copy_template() {
  local template_name="$1"
  local destination="$2"

  TEMPLATE_DIR="$HOME/dev/scaffolding/client-side-scaffolding"
  TEMPLATE_FILE="$TEMPLATE_DIR/$template_name"

  if [[ ! -f "$TEMPLATE_FILE" ]]; then
    handle_error "Template $template_name not found in $TEMPLATE_DIR."
  fi

  cp "$TEMPLATE_FILE" "$destination" || handle_error "Failed to copy $template_name to $destination."
  log "SUCCESS" "Copied $template_name to $destination."
}

create_vite() {
  local project_name="$1"
  log "INFO" "Creating Vite project $project_name"

  pnpm create vite@latest "$project_name" -- || handle_error "Error while creating the Vite project."

  cd "$HOME/dev/$project_name" || handle_error "Failed to navigate to project directory."

  log "INFO" "Installing dependencies"
  pnpm install || handle_error "Error while installing dependencies."
}

setup_tailwind() {
  log "INFO" "Adding Tailwind CSS, PostCSS, and Autoprefixer"

  pnpm install -D tailwindcss postcss autoprefixer || handle_error "Error while installing Tailwind dependencies"
  npx tailwindcss init -p

  copy_template "tailwind.config.js" "./tailwind.config.js"
  copy_template "./index.css" "./src/index.css"
  copy_template "./App.css" "./src/App.css"
  copy_template "./App.tsx" "./src/App.tsx"
}

setup_eslint() {
  log "INFO" "Adding ESLint configuration"
  pnpm create @eslint/config || handle_error "Error while creating ESLint config."
  copy_template "eslint.config.js" "./eslint.config.js"
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

  local help_file="$HOME/dev/scaffolding/client-side-scaffolding/my-client-help.txt"
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
      --app-type)
        APP_TYPE="$2"
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
      --skip-tailwind)
        SKIP_TAILWIND=true
        shift
        ;;
      --skip-eslint)
        SKIP_ESLINT=true
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

  if [[ -z "$APP_TYPE" ]]; then
    APP_TYPE=$(cat "$HOME/dev/scaffolding/client-side-scaffolding/my-client-app-cheatsheet.txt" | fzf --prompt "Select app type: ")
    if [[ -z "$APP_TYPE" ]]; then
      handle_error "No app type selected."
    fi
  fi

  if [[ -z "$PROJECT_NAME" ]]; then
    read -p "Enter project name: " input
    PROJECT_NAME=$(echo "$input" | sed -E "s/([a-z])([A-Z])/\1-\L\2/g" | tr "._ " "-")
    echo "$PROJECT_NAME"
  fi
}

main() {
  parse_flags "$@"

  cd "$HOME/dev" || handle_error "Failed to navigate to development directory."

  if [[ "$APP_TYPE" == "vite" ]]; then
    create_vite "$PROJECT_NAME"
  elif [[ "$APP_TYPE" == "next-app" ]]; then
    log "INFO" "Next.js app setup is not implemented yet."
    exit 1
  else
    handle_error "Unknown app type: $APP_TYPE"
  fi

  if [[ -z "$SKIP_TAILWIND" ]]; then
    setup_tailwind
  fi

  if [[ -z "$SKIP_ESLINT" ]]; then
    setup_eslint
  fi

  if [[ -z "$SKIP_GIT" ]]; then
    setup_git "$PROJECT_NAME" "$VISIBILITY"
  fi

  log "SUCCESS" "Project $PROJECT_NAME created successfully."
  log "INFO" "Ready to go 🚀"
}

main "$@"
