
# --- ------------------------------------------------------- DATA: AMI for the EC2 --- #
# --- ------------------------------------------------------- --------------------- --- #

# data "aws_ami" "ubuntu_linux" {
#
#   most_recent = true
#   owners      = ["canonical"]
#
#   filter {
#     name   = "name"
#     # values = ["al2023-ami-*-arm64"]
#     values = ["ami-0df008111109edab5"]
#   }
#
#   filter {
#     name   = "architecture"
#     values = ["arm64"]
#   }
#
#   filter {
#     name   = "state"
#     values = ["available"]
#   }
#
# }

# --- --------------------------------------------------------------- RESOURCE: EC2 --- #
# --- --------------------------------------------------------------- ------------- --- #

resource "aws_instance" "data_lake" {

  ami                    = var.instance_ami
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = var.security_group
  subnet_id              = var.subnet_id
  iam_instance_profile   = var.ec2_profile

  # --- Execute initial_setup --- #

  user_data_base64 = base64encode(<<-EOF
    #!/bin/bash
    set -e

    # Set environment variables for scripts
    export S3_BUCKET_NAME="${aws_s3_bucket.s3_deployment_files.id}"
    export PROJECT_ID="${var.pro_id}"
    export AWS_REGION="${var.pro_region}"

    # Log everything
    exec > >(tee /var/log/datalake-deployment.log) 2>&1
    
    echo " "
    echo "Download and execute SERVER setup"
    aws s3 cp s3://${aws_s3_bucket.s3_deployment_files.id}/server/scripts/server_setup.sh /tmp/server_setup.sh
    sudo chmod +x /tmp/server_setup.sh
    sudo /tmp/server_setup.sh
    
    echo " "
    echo "Download and execute DATABASE setup"
    aws s3 cp s3://${aws_s3_bucket.s3_deployment_files.id}/database/scripts/database_setup.sh /tmp/database_setup.sh
    sudo chmod +x /tmp/database_setup.sh
    sudo /tmp/database_setup.sh

    echo " "
    echo "Download and execute Datacollector setup"
    aws s3 cp s3://${aws_s3_bucket.s3_deployment_files.id}/datacollector/scripts/datacollector_setup.sh /tmp/datacollector_setup.sh
    sudo chmod +x /tmp/datacollector_setup.sh
    sudo /tmp/datacollector_setup.sh

    EOF
  )

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
    encrypted   = true
    
    tags = {
      Name        = "${var.pro_id}-datalake-root-volume"
      Environment = var.pro_env
      Project     = var.pro_id
    }
  }

  tags = {
    Name        = "${var.pro_id}-datalake-instance"
    Environment = var.pro_env
    Project     = var.pro_id
    Purpose     = "Create, Launch and Host dataplatform datasets and compute"
  }

}

# --- ------------------------------------------------------------ RESOURCE: EC2 IP --- #
# --- ------------------------------------------------------------- --------------- --- #

resource "aws_eip" "data_lake_eip" {

  instance = aws_instance.data_lake.id
  domain   = "vpc"

  tags = {
    Name        = "${var.pro_id}-data-eip"
    Environment = var.pro_env
    Project     = var.pro_id
  }

}

# --- -------------------------------------------- RESOURCE: DOCKER FILES PROVISION --- #
# --- -------------------------------------------- -------------------------------- --- #

# --- Create S3 bucket for file storage
resource "aws_s3_bucket" "s3_deployment_files" {

  bucket = "${var.pro_id}-datalake-deployment-files"
  tags = {
    Name        = "${var.pro_id}-datalake-deployment-files"
    Environment = var.pro_env
  }

}

# --- Configure bucket versioning
resource "aws_s3_bucket_versioning" "s3_deployment_files" {

  bucket = aws_s3_bucket.s3_deployment_files.id
  versioning_configuration {
    status = "Enabled"
  }

}

# --- ---------------------------------------------------------------- SERVER FILES --- #
# --- ---------------------------------------------------------------- ------------ --- #

resource "aws_s3_object" "server_configs" {

  for_each = fileset("${path.module}/server/configs", "**/*")
  
  bucket = aws_s3_bucket.s3_deployment_files.id
  key    = "server/configs/${each.value}"
  source = "${path.module}/server/configs/${each.value}"
  etag   = filemd5("${path.module}/server/configs/${each.value}")

}

resource "aws_s3_object" "server_build" {

  for_each = fileset("${path.module}/server/build", "**/*")
  
  bucket = aws_s3_bucket.s3_deployment_files.id
  key    = "server/build/${each.value}"
  source = "${path.module}/server/build/${each.value}"
  etag   = filemd5("${path.module}/server/build/${each.value}")

}

resource "aws_s3_object" "server_scripts" {

  for_each = fileset("${path.module}/server/scripts", "**/*")
  
  bucket = aws_s3_bucket.s3_deployment_files.id
  key    = "server/scripts/${each.value}"
  source = "${path.module}/server/scripts/${each.value}"
  etag   = filemd5("${path.module}/server/scripts/${each.value}")

}

# --- --------------------------------------------------------- DATACOLLECTOR FILES --- #
# --- --------------------------------------------------------- ------------------- --- #

resource "aws_s3_object" "datacollector_configs" {

  for_each = fileset("${path.module}/datacollector/configs", "**/*")
  
  bucket = aws_s3_bucket.s3_deployment_files.id
  key    = "datacollector/configs/${each.value}"
  source = "${path.module}/datacollector/configs/${each.value}"
  etag   = filemd5("${path.module}/datacollector/configs/${each.value}")

}

resource "aws_s3_object" "datacollector_build" {

  for_each = fileset("${path.module}/datacollector/build", "**/*")
  
  bucket = aws_s3_bucket.s3_deployment_files.id
  key    = "datacollector/build/${each.value}"
  source = "${path.module}/datacollector/build/${each.value}"
  etag   = filemd5("${path.module}/datacollector/build/${each.value}")

}

resource "aws_s3_object" "datacollector_scripts" {

  for_each = fileset("${path.module}/datacollector/scripts", "**/*")
  
  bucket = aws_s3_bucket.s3_deployment_files.id
  key    = "datacollector/scripts/${each.value}"
  source = "${path.module}/datacollector/scripts/${each.value}"
  etag   = filemd5("${path.module}/datacollector/scripts/${each.value}")

}

# --- -------------------------------------------------------------- DATABASE FILES --- #
# --- -------------------------------------------------------------- -------------- --- #

resource "aws_s3_object" "database_configs" {

  for_each = fileset("${path.module}/database/configs", "**/*")
  
  bucket = aws_s3_bucket.s3_deployment_files.id
  key    = "database/configs/${each.value}"
  source = "${path.module}/database/configs/${each.value}"
  etag   = filemd5("${path.module}/database/configs/${each.value}")

}

resource "aws_s3_object" "database_build" {

  for_each = fileset("${path.module}/database/build", "**/*")
  
  bucket = aws_s3_bucket.s3_deployment_files.id
  key    = "database/build/${each.value}"
  source = "${path.module}/database/build/${each.value}"
  etag   = filemd5("${path.module}/database/build/${each.value}")

}

resource "aws_s3_object" "database_scripts" {

  for_each = fileset("${path.module}/database/scripts", "**/*")
  
  bucket = aws_s3_bucket.s3_deployment_files.id
  key    = "database/scripts/${each.value}"
  source = "${path.module}/database/scripts/${each.value}"
  etag   = filemd5("${path.module}/database/scripts/${each.value}")

}

