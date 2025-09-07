#!/bin/bash

# Read environment variables set by user_data
export S3_BUCKET_NAME="infradex-datalake-deployment-files"
export PROJECT_ID="infradex"
export AWS_REGION="us-east-1"

# Continue logging to the same file started by user_data_base64 in the main.tf
exec >> /var/log/datalake-deployment.log 2>&1

echo " "
echo "=== DATABASE DEPLOYMENT ==="
echo "Starting DATABASE deployment at $(date)"
echo "Using S3 bucket: $S3_BUCKET_NAME"
echo "Project ID: $PROJECT_ID"
echo "AWS Region: $AWS_REGION"
echo " "

# Create directory structure
echo "Creating directory structure..."
mkdir -p /opt/infradex/database/{build,configs,scripts}

# Download files from S3 using environment variable
echo "Downloading files from S3 bucket: $S3_BUCKET_NAME"
aws s3 sync s3://$S3_BUCKET_NAME/database/build/ /opt/infradex/database/build/ || exit 1
aws s3 sync s3://$S3_BUCKET_NAME/database/configs/ /opt/infradex/database/configs/ || exit 1
aws s3 sync s3://$S3_BUCKET_NAME/database/scripts/ /opt/infradex/database/scripts/ || exit 1

echo "Files downloaded successfully. Contents:"
ls -la /opt/infradex/database/build/
ls -la /opt/infradex/database/configs/
ls -la /opt/infradex/database/scripts/

# Set permissions
echo "Setting permissions..."
chown -R ubuntu:ubuntu /opt/infradex
chmod +x /opt/infradex/database/scripts/*.sh
chmod +x /opt/infradex/database/configs/*.xml

# Build Docker image
echo "Building database Docker image..."

if [ -f "opt/infradex/database/build/database.Dockerfile" ]; then
  cd /opt/infradex
  docker build --no-cache -f database/build/database.Dockerfile -t database . || exit 1
  echo "Database Docker image built successfully"
 
# In your database setup script, add:
echo "Creating Docker network for container communication..."
docker network create infradex-network 2>/dev/null || echo "Network already exists"

  # Run container
  echo "Starting database container..."
  docker run -d \
    --name database-clickhouse \
    -p 8123:8123 \
    -p 9000:9000 \
    database:latest \
    
  echo "Database container started successfully"
else
  echo "ERROR: database.Dockerfile not found"
  exit 1
fi

echo "Deployment completed successfully at $(date)"

