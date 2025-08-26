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

resource "aws_instance" "data_pipeline" {
  ami                    = data.aws_ami.amazon_linux.id
  key_name               = "${var.pro_id}-key-pair"
  instance_type          = var.instance_type

  vpc_security_group_ids = var.security_group
  subnet_id              = var.subnet_id

  # Add more storage for Docker containers and data
  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
    
    tags = {
      Name = "${var.pro_id}-root-volume"
    }
  }

  # User data script for Docker setup
  user_data = base64encode(templatefile("${path.module}/../../scripts/userdata.sh", {
    project_name = var.pro_id
  }))

  tags = {
    Name        = "${var.pro_id}-instance"
    Environment = var.pro_environment
    Purpose     = "CEX Trading Data Pipeline"
    Project     = "infradex"
  }

}

  resource "aws_eip" "data_pipeline_eip" {
    instance = aws_instance.data_pipeline.id
    domain   = "vpc"

    tags = {
      Name = "${var.pro_id}-eip"
    }

}

# Provisioning Docker files after instance creation
resource "null_resource" "deploy_docker_files" {
  depends_on = [aws_instance.data_pipeline]

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(var.private_key_path)
    host        = aws_eip.data_pipeline_eip.public_ip
    timeout     = "10m"
  }

  # Create directory structure
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /opt/infradex/docker",
      "sudo chown -R ec2-user:ec2-user /opt/infradex"
    ]
  }

  # Copy Docker files
  provisioner "file" {
    source      = "${path.module}/../../docker/"
    destination = "/opt/infradex/docker/"
  }

  # Copy scripts
  provisioner "file" {
    source      = "${path.module}/../../scripts/"
    destination = "/opt/infradex/scripts/"
  }

  # Deploy services
  provisioner "remote-exec" {
    inline = [
      "cd /opt/infradex/docker",
      "sudo chmod +x /opt/infradex/scripts/*.sh",
      "sudo docker-compose up -d database",
      "sleep 30",  # Wait for database to be ready
      "sudo docker-compose up -d collector",
      "sudo docker ps"  # Show running containers
    ]
  }
}


