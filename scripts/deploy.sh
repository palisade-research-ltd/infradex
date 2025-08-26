#!/bin/bash

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    # Check if aws cli is installed
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if aws is configured
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS CLI is not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    print_success "Prerequisites check passed!"
}

# Generate SSH key pair if not exists
generate_ssh_key() {
    local key_path="$HOME/.ssh/data-pipeline-key"
    
    if [ ! -f "$key_path" ]; then
        print_status "Generating SSH key pair..."
        ssh-keygen -t rsa -b 2048 -f "$key_path" -N "" -C "data-pipeline-key"
        chmod 600 "$key_path"
        chmod 644 "${key_path}.pub"
        print_success "SSH key pair generated at $key_path"
    else
        print_status "SSH key already exists at $key_path"
    fi
    
    echo "$key_path"
}

