#!/bin/bash

# Read environment variables from user_data (not hardcoded)
S3_BUCKET_NAME=${S3_BUCKET_NAME:-"infradex-dataplatform-deployment-files"}
PROJECT_ID=${PROJECT_ID:-"infradex"}
AWS_REGION=${AWS_REGION:-"us-east-1"}

# Continue logging to the same file started by user_data
exec >> /var/log/datacollector-deployment.log 2>&1

echo "Starting data collector deployment at $(date)"
echo "Using S3 bucket: $S3_BUCKET_NAME"
echo "Project ID: $PROJECT_ID"
echo "AWS Region: $AWS_REGION"

# Create directory structure
echo "Creating directory structure..."
mkdir -p /opt/infradex/collector/{build,configs,scripts}

# Download files from S3
echo "Downloading files from S3 bucket: $S3_BUCKET_NAME"
aws s3 sync s3://$S3_BUCKET_NAME/collector/build/ /opt/infradex/collector/build/ || exit 1
aws s3 sync s3://$S3_BUCKET_NAME/collector/configs/ /opt/infradex/collector/configs/ || exit 1
aws s3 sync s3://$S3_BUCKET_NAME/collector/scripts/ /opt/infradex/collector/scripts/ || exit 1

echo "Files downloaded successfully."

# Set permissions
echo "Setting permissions..."
chown -R ec2-user:ec2-user /opt/infradex
chmod +x /opt/infradex/collector/build/collector_* 2>/dev/null || true
chmod +x /opt/infradex/collector/scripts/*.sh 2>/dev/null || true

# Change to collector directory for proper build context
# cd /opt/infradex/collector

# Build Docker image from the correct location
echo "Building Collector Docker Image..."
if [ -f "opt/infradex/collector/build/collector.Dockerfile" ]; then
  # Build with correct context - current directory contains the files
  docker build -f opt/infradex/collector/build/collector.Dockerfile -t collector:latest . || exit 1
  echo "Collector Docker image built successfully"
  
  # Wait for ClickHouse to be ready before starting collector
  echo "Waiting for ClickHouse to be ready..."
  for i in {1..30}; do
    if curl -s http://localhost:8123/ping | grep -q "Ok"; then
      echo "ClickHouse is ready!"
      break
    else
      echo "Waiting for ClickHouse... ($i/30)"
      sleep 10
    fi
  done
  
  # Run collector container with proper configuration
  echo "Starting collector container..."
  docker run -d \
    --name datacollector-rust \
    -e RUST_LOG=info \
    -e CLICKHOUSE_URL=http://clickhouse:8123 \
    -v /var/log:/app/logs \
    --restart unless-stopped \
    collector:latest || exit 1
    
  echo "Collector container started successfully"
  
  # Verify both containers are running
  echo "Container status:"
  docker ps
  
else
  echo "ERROR: collector.Dockerfile not found in build/"
  ls -la build/
  exit 1
fi

echo "Collector deployment completed successfully at $(date)"
