#!/bin/bash

# read environment variables set by user_data
export S3_BUCKET_NAME="infradex-datalake-deployment-files"
export PROJECT_ID="infradex"
export AWS_REGION="us-east-1"

# Continue logging to the same file started by user_data_base64 in the main.tf
exec >> /var/log/datalake-deployment.log 2>&1

echo "Starting SERVER setup at $(date)"
echo "Using S3 bucket: $S3_BUCKET_NAME"
echo "Project ID: $PROJECT_ID"
echo "AWS Region: $AWS_REGION"

# Update system
echo "Updating system packages..."
sudo apt update -y
sudo apt install -y aws-cli docker git

# Configure AWS CLI region
aws configure set default.region $AWS_REGION

# Start Docker service
echo "Starting Docker service..."
systemctl start docker
systemctl enable docker
usermod -a -G docker ubuntu

# Wait for Docker to be ready
echo "Waiting for Docker to be ready..."
while ! docker info >/dev/null 2>&1; do
  echo "Docker not ready yet, waiting..."
  sleep 2
done
echo "Docker is ready!"

# Create a Docker network for container communication
echo "Creating Docker network..."
docker network create infradex-network 2>/dev/null || echo "Network already exists"
  
# Create directory structure
echo "Creating directory structure..."
mkdir -p /opt/infradex/server/{build,configs,scripts}

# Download files from S3
echo "Downloading files from S3 bucket: $S3_BUCKET_NAME"
aws s3 sync s3://$S3_BUCKET_NAME/server/build/ /opt/infradex/server/build/ || exit 1
aws s3 sync s3://$S3_BUCKET_NAME/server/configs/ /opt/infradex/server/configs/ || exit 1
aws s3 sync s3://$S3_BUCKET_NAME/server/scripts/ /opt/infradex/server/scripts/ || exit 1

echo "Files downloaded successfully. Contents:"
ls -la /opt/infradex/server/build/
ls -la /opt/infradex/server/configs/
ls -la /opt/infradex/server/scripts/

