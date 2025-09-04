#!/bin/bash

# Read environment variables set by user_data
export S3_BUCKET_NAME="infradex-dataplatform-deployment-files"
export PROJECT_ID="infradex"
export AWS_REGION="us-east-1"

# Redirect all output to log file  
exec > >(tee /var/log/database-deployment.log) 2>&1

echo "Starting database deployment at $(date)"
echo "Using S3 bucket: $S3_BUCKET_NAME"
echo "Project ID: $PROJECT_ID"
echo "AWS Region: $AWS_REGION"

# Update system
echo "Updating system packages..."
yum update -y
yum install -y aws-cli docker git

# Configure AWS CLI region
aws configure set default.region $AWS_REGION

# Start Docker service
echo "Starting Docker service..."
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Wait for Docker to be ready
echo "Waiting for Docker to be ready..."
while ! docker info >/dev/null 2>&1; do
  echo "Docker not ready yet, waiting..."
  sleep 2
done
echo "Docker is ready!"

# Database deployment
echo "=== DATABASE DEPLOYMENT ==="

# Create directory structure
echo "Creating directory structure..."
mkdir -p /opt/infradex/database/{build,configs,scripts}

# Download files from S3 using environment variable
echo "Downloading files from S3 bucket: $S3_BUCKET_NAME"
aws s3 sync s3://$S3_BUCKET_NAME/database/build/ /opt/infradex/database/build/ || exit 1
aws s3 sync s3://$S3_BUCKET_NAME/database/configs/ /opt/infradex/database/configs/ || exit 1
aws s3 sync s3://$S3_BUCKET_NAME/database/scripts/ /opt/infradex/database/scripts/ || exit 1

echo "Files downloaded successfully"

# Set permissions
echo "Setting permissions..."
chown -R ec2-user:ec2-user /opt/infradex
chmod +x /opt/infradex/database/scripts/*.sh
chmod +x /opt/infradex/database/configs/*.xml

# Build Docker image
echo "Building database Docker image..."

if [ -f "opt/infradex/database/build/database.Dockerfile" ]; then
  docker build -f opt/infradex/database/build/database.Dockerfile -t database . || exit 1
  echo "Database Docker image built successfully"
  
  # Run container
  echo "Starting database container..."
  docker run -d \
    --name database-clickhouse \
    -p 8123:8123 \
    -p 9000:9000 \
    database:latest
    
  echo "Database container started successfully"
else
  echo "ERROR: database.Dockerfile not found"
  exit 1
fi

echo "Deployment completed successfully at $(date)"

