#!/bin/bash
# File: scripts/deploy.sh
# Complete deployment orchestration for infradex

set -e

# Colors and logging functions (same as before)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed"
        exit 1
    fi
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed"
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS CLI is not configured"
        exit 1
    fi
    
    print_success "Prerequisites check passed!"
}

# Generate SSH keys
generate_ssh_key() {
    local key_path="$HOME/.ssh/infradex-key"
    
    if [ ! -f "$key_path" ]; then
        print_status "Generating SSH key pair..."
        ssh-keygen -t rsa -b 2048 -f "$key_path" -N "" -C "infradex-key"
        chmod 600 "$key_path"
        chmod 644 "${key_path}.pub"
        print_success "SSH key pair generated at $key_path"
    fi
    
    echo "$key_path"
}

# Deploy infrastructure
deploy_infrastructure() {
    print_status "Deploying infrastructure..."
    
    local ssh_key_path=$(generate_ssh_key)
    local public_key=$(cat "${ssh_key_path}.pub")
    
    cd envs/dev
    
    # Create terraform.tfvars
    cat > terraform.tfvars <<EOF
pro_id = "infradex"
pro_environment = "dev" 
pro_region = "us-west-2"
instance_type = "t3.micro"  # Free tier eligible
public_key = "${public_key}"
private_key_path = "${ssh_key_path}"
EOF
    
    # Initialize and apply Terraform
    terraform init
    terraform plan -var-file=terraform.tfvars
    terraform apply -var-file=terraform.tfvars -auto-approve
    
    cd ../..
    print_success "Infrastructure deployed successfully!"
}

# Monitor deployment
monitor_deployment() {
    print_status "Monitoring service deployment..."
    
    cd envs/dev
    local instance_ip=$(terraform output -raw instance_public_ip)
    cd ../..
    
    local max_attempts=20
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        attempt=$((attempt + 1))
        
        print_status "Attempt $attempt/$max_attempts - Checking services..."
        
        # Check ClickHouse
        if curl -s -f "http://$instance_ip:8123/ping" > /dev/null 2>&1; then
            print_success "ClickHouse is healthy!"
            
            # Check if collector is running via SSH
            if ssh -o StrictHostKeyChecking=no -i ~/.ssh/infradex-key ec2-user@$instance_ip "sudo docker ps | grep collector" > /dev/null 2>&1; then
                print_success "Collector service is running!"
                print_success "Deployment completed successfully!"
                
                echo ""
                echo "=================================================="
                echo "           INFRADEX DEPLOYMENT SUCCESSFUL!"
                echo "=================================================="
                echo ""
                echo "Instance IP: $instance_ip"
                echo "ClickHouse URL: http://$instance_ip:8123"
                echo "SSH Command: ssh -i ~/.ssh/infradex-key ec2-user@$instance_ip"
                echo ""
                echo "Available endpoints:"
                echo "  - ClickHouse HTTP: http://$instance_ip:8123"
                echo "  - Collector Metrics: http://$instance_ip:8090/metrics" 
                echo "  - Collector Health: http://$instance_ip:8091/health"
                echo ""
                return 0
            fi
        fi
        
        print_status "Services not ready yet, waiting 30 seconds..."
        sleep 30
    done
    
    print_warning "Services may not be fully ready. Check manually."
}

# Test deployment
test_deployment() {
    print_status "Testing deployment..."
    
    cd envs/dev
    local instance_ip=$(terraform output -raw instance_public_ip)
    cd ../..
    
    # Test ClickHouse
    if curl -s "http://$instance_ip:8123/?query=SELECT version()" | grep -q "ClickHouse"; then
        print_success "ClickHouse is responding correctly!"
    else
        print_warning "ClickHouse may not be fully ready"
    fi
    
    # Test database schema
    if curl -s "http://$instance_ip:8123/?query=SHOW DATABASES" | grep -q "trading_data"; then
        print_success "Trading database schema is ready!"
    else
        print_warning "Trading database may not be initialized yet"
    fi
    
    # Show running containers
    print_status "Running containers:"
    ssh -o StrictHostKeyChecking=no -i ~/.ssh/infradex-key ec2-user@$instance_ip "sudo docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
}

# Main deployment function
main() {
    local command=${1:-"deploy"}
    
    case $command in
        "deploy")
            check_prerequisites
            deploy_infrastructure
            monitor_deployment
            test_deployment
            ;;
        "test")
            test_deployment
            ;;
        "destroy")
            print_warning "This will destroy all infrastructure. Are you sure? (y/N)"
            read -r confirmation
            if [ "$confirmation" = "y" ]; then
                cd envs/dev
                terraform destroy -var-file=terraform.tfvars -auto-approve
                cd ../..
                print_success "Infrastructure destroyed!"
            fi
            ;;
        *)
            echo "Usage: $0 [deploy|test|destroy]"
            ;;
    esac
}

main "$@"
