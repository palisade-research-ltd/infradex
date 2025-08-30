
# --- -------------------------------------------- RESOURCE: DOCKER FILES PROVISION --- #
# --- -------------------------------------------- -------------------------------- --- #

# --- Create S3 bucket for file storage
resource "aws_s3_bucket" "s3_deployment_files" {

  bucket = "${var.pro_id}-datalake-deployment-files"
  
  tags = {
    Name        = "${var.pro_id}-datalake-deployment-files"
    Environment = var.pro_environment
  }
}

# --- Configure bucket versioning
resource "aws_s3_bucket_versioning" "s3_deployment_files" {

  bucket = aws_s3_bucket.s3_deployment_files.id
  versioning_configuration {
    status = "Enabled"
  }

}

# --- ------------------------------------------------------------- COLLECTOR FILES --- #
# --- ------------------------------------------------------------- --------------- --- #

resource "aws_s3_object" "collector_build" {

  for_each = fileset("${path.module}/collector/build", "**/*")
  
  bucket = aws_s3_bucket.s3_deployment_files.id
  key    = "collector/build/${each.value}"
  source = "${path.module}/collector/build/${each.value}"
  etag   = filemd5("${path.module}/collector/build/${each.value}")

}

resource "aws_s3_object" "collector_configs" {

  for_each = fileset("${path.module}/collector/configs", "**/*")
  
  bucket = aws_s3_bucket.s3_deployment_files.id
  key    = "collector/configs/${each.value}"
  source = "${path.module}/collector/configs/${each.value}"
  etag   = filemd5("${path.module}/collector/configs/${each.value}")

}

resource "aws_s3_object" "collector_scripts" {

  for_each = fileset("${path.module}/collector/scripts", "**/*")
  
  bucket = aws_s3_bucket.s3_deployment_files.id
  key    = "collector/scripts/${each.value}"
  source = "${path.module}/collector/scripts/${each.value}"
  etag   = filemd5("${path.module}/collector/scripts/${each.value}")

}

# --- -------------------------------------------------------------- DATABASE FILES --- #
# --- -------------------------------------------------------------- -------------- --- #

resource "aws_s3_object" "database_build" {

  for_each = fileset("${path.module}/database/build", "**/*")
  
  bucket = aws_s3_bucket.s3_deployment_files.id
  key    = "database/build/${each.value}"
  source = "${path.module}/database/build/${each.value}"
  etag   = filemd5("${path.module}/database/build/${each.value}")

}

resource "aws_s3_object" "database_configs" {

  for_each = fileset("${path.module}/database/configs", "**/*")
  
  bucket = aws_s3_bucket.s3_deployment_files.id
  key    = "database/configs/${each.value}"
  source = "${path.module}/database/configs/${each.value}"
  etag   = filemd5("${path.module}/database/configs/${each.value}")

}

resource "aws_s3_object" "database_scripts" {

  for_each = fileset("${path.module}/database/scripts", "**/*")
  
  bucket = aws_s3_bucket.s3_deployment_files.id
  key    = "database/scripts/${each.value}"
  source = "${path.module}/database/scripts/${each.value}"
  etag   = filemd5("${path.module}/database/scripts/${each.value}")

}

# --- ------------------------------------------------------- DATA: AMI for the EC2 --- #
# --- ------------------------------------------------------- --------------------- --- #

data "aws_ami" "amazon_linux" {

  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }

}

# --- --------------------------------------------------------------- RESOURCE: EC2 --- #
# --- --------------------------------------------------------------- ------------- --- #

resource "aws_instance" "data_collector" {

  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  vpc_security_group_ids = var.security_group
  subnet_id              = var.subnet_id

  # User data script to download and deploy files
  user_data_base64 = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y aws-cli docker docker-compose-plugin
    
    # Start Docker service
    systemctl start docker
    systemctl enable docker
    usermod -a -G docker ec2-user
    
    # Create directory structure
    mkdir -p created_test_dir 
    mkdir -p /opt/infradex/database
    mkdir -p /opt/infradex/database/build
    mkdir -p /opt/infradex/database/configs
    mkdir -p /opt/infradex/database/scripts
    
    # Log completion
    echo "Deployment completed successfully at $(date)" > /var/log/deployment.log

    # Download files from S3
    aws s3 sync s3://${aws_s3_bucket.s3_deployment_files.id}/database/build/ /opt/infradex/database/build/
    aws s3 sync s3://${aws_s3_bucket.s3_deployment_files.id}/database/configs/ /opt/infradex/database/configs/
    aws s3 sync s3://${aws_s3_bucket.s3_deployment_files.id}/database/scripts/ /opt/infradex/database/scripts/
    
    # Set permissions
    chown -R ec2-user:ec2-user /opt/infradex
    chmod +x /opt/infradex/database/scripts/*.sh
    
    # Navigate to database directory and start services
    cd /opt/infradex/database
    sudo -u ec2-user docker compose up -d database
    
    # Wait for services to start and show status
    sleep 30
    docker ps
    
    # Log completion
    echo "Deployment completed successfully at $(date)" > /var/log/deployment.log
    EOF
  )

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
    encrypted   = true
    
    tags = {
      Name        = "${var.pro_id}-root-volume"
      Environment = var.pro_environment
      Project     = var.pro_id
    }
  }

  tags = {
    Name        = "${var.pro_id}-data-instance"
    Environment = var.pro_environment
    Project     = var.pro_id
    Purpose     = "CEX Trading Data Pipeline"
  }

}

# --- ------------------------------------------------------------ RESOURCE: EC2 IP --- #
# --- ------------------------------------------------------------- --------------- --- #

resource "aws_eip" "data_collector_eip" {

  instance = aws_instance.data_collector.id
  domain   = "vpc"

  tags = {
    Name        = "${var.pro_id}-data-eip"
    Environment = var.pro_environment
    Project     = var.pro_id
  }

}

