
#!/bin/bash

# Builds a Docker image from test.Dockerfile and pushes it to Docker Hub

set -euo pipefail  # Exit on error, undefined variables, and pipe failures

# Configuration - Edit these variables as needed
DOCKERFILE_NAME="dataplatform.Dockerfile"
DOCKER_USERNAME="${DOCKER_USERNAME:-}"
DOCKER_PAT="${DOCKER_PAT:-}"
DOCKER_REPO="${DOCKER_REPO:-$DOCKER_USERNAME}"
IMAGE_NAME="${IMAGE_NAME:-microservice}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
BUILD_CONTEXT="${BUILD_CONTEXT:-.}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if required tools are installed
check_dependencies() {
    log_info "Checking dependencies..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    log_success "Docker is available"
}

# Function to validate required environment variables
validate_environment() {
    log_info "Validating environment variables..."
    
    if [[ -z "$DOCKER_USERNAME" ]]; then
        log_error "DOCKER_USERNAME environment variable is required"
        log_info "Set it with: export DOCKER_USERNAME=your-dockerhub-username"
        exit 1
    fi
    
    if [[ -z "$DOCKER_PAT" ]]; then
        log_error "DOCKER_PAT environment variable is required"
        log_info "Set it with: export DOCKER_PAT=your-dockerhub-personal-access-token"
        log_warning "Use a Docker Hub Personal Access Token instead of your password for security"
        exit 1
    fi
    
    log_success "Environment variables validated"
}

# Function to check if Dockerfile exists
check_dockerfile() {
    log_info "Checking for Dockerfile: $DOCKERFILE_NAME"
    
    if [[ ! -f "$DOCKERFILE_NAME" ]]; then
        log_error "Dockerfile '$DOCKERFILE_NAME' not found in current directory"
        log_info "Make sure the file exists and try again"
        exit 1
    fi
    
    log_success "Dockerfile found: $DOCKERFILE_NAME"
}

# Function to login to Docker Hub
docker_login() {
    log_info "Logging into Docker Hub..."
    
    # Use --password-stdin for security (avoids password in process list)
    if echo "$DOCKER_PAT" | docker login --username "$DOCKER_USERNAME" --password-stdin; then
        log_success "Successfully logged into Docker Hub"
    else
        log_error "Failed to login to Docker Hub"
        log_info "Please check your username and personal-access-token"
        exit 1
    fi
}

# Function to build Docker image
build_image() {
    local full_image_name="$DOCKER_REPO/$IMAGE_NAME:$IMAGE_TAG"
    
    log_info "Building Docker image: $full_image_name"
    log_info "Using Dockerfile: $DOCKERFILE_NAME"
    log_info "Build context: $BUILD_CONTEXT"
    
    # Build the image with proper error handling
    if docker build \
        --file "$DOCKERFILE_NAME" \
        --tag "$full_image_name" \
        --progress=plain \
        "$BUILD_CONTEXT"; then
        log_success "Docker image built successfully: $full_image_name"
        return 0
    else
        log_error "Failed to build Docker image"
        exit 1
    fi
}

# Function to push image to Docker Hub
push_image() {
    local full_image_name="$DOCKER_REPO/$IMAGE_NAME:$IMAGE_TAG"
    
    log_info "Pushing image to Docker Hub: $full_image_name"
    
    if docker push "$full_image_name"; then
        log_success "Image pushed successfully to Docker Hub"
        log_info "Image URL: https://hub.docker.com/r/$DOCKER_REPO/$IMAGE_NAME"
    else
        log_error "Failed to push image to Docker Hub"
        exit 1
    fi
}

# Function to cleanup (logout)
cleanup() {
    log_info "Cleaning up..."
    docker logout &> /dev/null || true
    log_info "Logged out from Docker Hub"
}

# Function to display usage information
usage() {
    cat << EOF
Docker Build and Push Script

Usage: $0 [OPTIONS]

This script builds a Docker image from test.Dockerfile and pushes it to Docker Hub.

Environment Variables (Required):
  DOCKER_USERNAME    Your Docker Hub username
  DOCKER_PAT         Your Docker Hub Personal Access Token

Environment Variables (Optional):
  IMAGE_NAME         Image name (default: microservice)
  IMAGE_TAG          Image tag (default: latest)
  BUILD_CONTEXT      Build context directory (default: .)

Examples:
  # Basic usage (set environment variables first)
  export DOCKER_USERNAME=myusername
  export DOCKER_PASSWORD=my-personal-access-token
  $0

  # With custom image name and tag
  export DOCKER_REPO=my-repo-in-dockerhub
  export DOCKER_PAT=my-access-token
  export IMAGE_NAME=my-microservice
  export IMAGE_TAG=v0.0.1
  $0

Security Note:
  Use Docker Hub Personal Access Tokens instead of passwords for better security.
  Create tokens at: https://hub.docker.com/settings/security

EOF
}

# Function to display script information
show_info() {
    log_info "Docker Build and Push Script"
    log_info "=============================="
    log_info "Dockerfile: $DOCKERFILE_NAME"
    log_info "Docker Username: $DOCKER_USERNAME"
    log_info "DockerHub Repo/Org: $DOCKER_REPO"
    log_info "Image Name: $DOCKER_REPO/$IMAGE_NAME:$IMAGE_TAG"
    log_info "Build Context: $BUILD_CONTEXT"
    echo
}

# Main execution function
main() {
    # Set trap to cleanup on exit
    trap cleanup EXIT
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    # Execute main workflow
    log_info "Starting Docker build and push process..."
    echo
    
    show_info
    check_dependencies
    validate_environment
    check_dockerfile
    docker_login
    build_image
    push_image
    
    echo
    log_success "Docker build and push completed successfully!"
    log_info "Your image is now available at: https://hub.docker.com/r/$DOCKER_REPO/$IMAGE_NAME"
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
