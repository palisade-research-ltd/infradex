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

# Initialize and validate terraform
init_terraform() {
    print_status "Initializing Terraform..."
    
    cd terraform
    
    # Initialize terraform
    terraform init
    
    # Validate configuration
    terraform validate
    
    print_success "Terraform initialized and validated!"
    cd ..
}

# Plan terraform deployment
plan_terraform() {
    print_status "Planning Terraform deployment..."
    
    cd terraform
    
    local ssh_key_path=$(generate_ssh_key)
    local public_key=$(cat "${ssh_key_path}.pub")
    
    # Create terraform.tfvars file
    cat > terraform.tfvars <<EOF
aws_region = "us-east-1"
project_name = "data-pipeline"
environment = "dev"
instance_type = "t3.micro"
public_key = "${public_key}"
private_key_path = "${ssh_key_path}"
EOF
    
    # Plan deployment
    terraform plan -var-file=terraform.tfvars
    
    print_success "Terraform plan completed!"
    cd ..
}

# Apply terraform configuration
apply_terraform() {
    print_status "Applying Terraform configuration..."
    
    cd terraform
    
    # Apply configuration
    terraform apply -var-file=terraform.tfvars -auto-approve
    
    # Get outputs
    local instance_ip=$(terraform output -raw instance_public_ip)
    local clickhouse_url=$(terraform output -raw clickhouse_url)
    local ml_api_url=$(terraform output -raw ml_model_api_url)
    local pipeline_api_url=$(terraform output -raw data_pipeline_api_url)
    local ssh_command=$(terraform output -raw ssh_command)
    
    print_success "Terraform deployment completed!"
    
    echo ""
    echo "=================================================="
    echo "           DEPLOYMENT SUCCESSFUL!"
    echo "=================================================="
    echo ""
    echo "Instance IP: $instance_ip"
    echo "ClickHouse URL: $clickhouse_url"
    echo "ML Model API: $ml_api_url"
    echo "Data Pipeline API: $pipeline_api_url"
    echo ""
    echo "SSH Command: $ssh_command"
    echo ""
    echo "Note: Services may take 5-10 minutes to fully initialize."
    echo "You can monitor the setup by SSHing to the instance and running:"
    echo "  sudo docker logs -f data-pipeline-service"
    echo "  sudo docker logs -f ml-model-service"
    echo "  sudo docker logs -f clickhouse-server"
    echo ""
    
    cd ..
}

# Wait for services to be ready
wait_for_services() {
    local instance_ip=$1
    local max_attempts=30
    local attempt=0
    
    print_status "Waiting for services to be ready..."
    
    while [ $attempt -lt $max_attempts ]; do
        attempt=$((attempt + 1))
        
        # Check ClickHouse
        if curl -s -f "http://$instance_ip:8123/ping" > /dev/null 2>&1; then
            print_success "ClickHouse is ready!"
            break
        fi
        
        print_status "Attempt $attempt/$max_attempts - Services not ready yet, waiting..."
        sleep 30
    done
    
    if [ $attempt -eq $max_attempts ]; then
        print_warning "Services may not be fully ready yet. Please check manually."
    fi
}

# Test the deployment
test_deployment() {
    print_status "Testing deployment..."
    
    cd terraform
    local instance_ip=$(terraform output -raw instance_public_ip)
    cd ..
    
    echo ""
    echo "Testing services..."
    
    # Test ClickHouse
    print_status "Testing ClickHouse..."
    if curl -s "http://$instance_ip:8123/ping" | grep -q "Ok"; then
        print_success "ClickHouse is responding!"
    else
        print_warning "ClickHouse may not be ready yet."
    fi
    
    # Test Data Pipeline API
    print_status "Testing Data Pipeline API..."
    if curl -s "http://$instance_ip:8080/health" | grep -q "healthy"; then
        print_success "Data Pipeline API is healthy!"
    else
        print_warning "Data Pipeline API may not be ready yet."
    fi
    
    # Test ML Service
    print_status "Testing ML Service..."
    if curl -s "http://$instance_ip:5000/health" | grep -q "healthy"; then
        print_success "ML Service is healthy!"
    else
        print_warning "ML Service may not be ready yet."
    fi
    
    # Test ML prediction
    print_status "Testing ML prediction..."
    local prediction_response=$(curl -s -X POST "http://$instance_ip:5000/predict" \
        -H "Content-Type: application/json" \
        -d '{"features": [1.0, 2.0, 3.0]}')
    
    if echo "$prediction_response" | grep -q "success"; then
        print_success "ML prediction is working!"
    else
        print_warning "ML prediction may not be ready yet."
    fi
    
    echo ""
    echo "=================================================="
    echo "           TESTING COMPLETED!"
    echo "=================================================="
    echo ""
    echo "All services should now be available at:"
    echo "  ClickHouse: http://$instance_ip:8123"
    echo "  Data Pipeline: http://$instance_ip:8080"
    echo "  ML Service: http://$instance_ip:5000"
    echo ""
}

# Destroy infrastructure
destroy_infrastructure() {
    print_warning "This will destroy all infrastructure. Are you sure? (y/N)"
    read -r confirmation
    
    if [ "$confirmation" = "y" ] || [ "$confirmation" = "Y" ]; then
        print_status "Destroying infrastructure..."
        
        cd terraform
        terraform destroy -var-file=terraform.tfvars -auto-approve
        cd ..
        
        print_success "Infrastructure destroyed!"
    else
        print_status "Destruction cancelled."
    fi
}

# Main function
main() {
    local command=${1:-"deploy"}
    
    case $command in
        "deploy")
            check_prerequisites
            init_terraform
            plan_terraform
            apply_terraform
            
            cd terraform
            local instance_ip=$(terraform output -raw instance_public_ip)
            cd ..
            
            wait_for_services "$instance_ip"
            test_deployment
            ;;
        "plan")
            check_prerequisites
            init_terraform
            plan_terraform
            ;;
        "test")
            test_deployment
            ;;
        "destroy")
            destroy_infrastructure
            ;;
        "help"|"-h"|"--help")
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  deploy   - Deploy the infrastructure (default)"
            echo "  plan     - Plan the deployment without applying"
            echo "  test     - Test the deployed services"
            echo "  destroy  - Destroy the infrastructure"
            echo "  help     - Show this help message"
            ;;
        *)
            print_error "Unknown command: $command"
            echo "Use '$0 help' for usage information."
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
