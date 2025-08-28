
# --- -------------------------------------------- RESOURCE: DOCKER FILES PROVISION --- #
# --- -------------------------------------------- -------------------------------- --- #

resource "null_resource" "updload_datalake_config_files" {

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(var.private_key_path)
    host        = var.public_ip
    timeout     = "10m"
  }

  # Create directory structure
  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /opt/infradex/datalake",
      "sudo mkdir -p /opt/infradex/datalake/configs",
      "sudo mkdir -p /opt/infradex/datalake/scripts",
      "sudo chown -R ec2-user:ec2-user /opt/infradex"
    ]
  }

  # Copy Database Config Files
  provisioner "file" {
    source      = "${path.module}/../../datalake/configs/"
    destination = "/opt/infradex/datalake/"
  }

  # Copy Database Config Scripts
  provisioner "file" {
    source      = "${path.module}/../../datalake/scripts/"
    destination = "/opt/infradex/datalake/"
  }

  # Deploy services
  provisioner "remote-exec" {
    inline = [
      "cd /opt/infradex/datalake",
      "sudo chmod +x /opt/infradex/datalake/scripts/*.sh",
    ]
  }

}

