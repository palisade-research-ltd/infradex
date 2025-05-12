
// --- ------------------------------------------------------------------------------ COMPUTE --- //
// --- ------------------------------------------------------------------------------ ------- --- //

resource "google_compute_instance" "compute_instance" {
  
  project      = var.prj_project_id
  zone         = var.prj_zone
  name         = var.cmp_instance_name
  machine_type = var.cmp_instance_type

  boot_disk {
    initialize_params {
      image = var.cmp_instance_image
      size = 20
      type = "pd-ssd"
    }
  }

  provisioner "remote-exec" {
  
    inline = [
      "sudo mkdir -p /home/scripts",
      "sudo chmod 777 /home/scripts"
    ]
    
    connection {
      type        = "ssh"
      user        = var.gcp_ssh_usr_0
      private_key = var.gcp_ssh_prv_0
      host        = self.network_interface[0].access_config[0].nat_ip
    }
  
  }

  provisioner "file" {
    source      = "${path.module}/scripts"
    destination = "/home/scripts"
    connection {
      type        = "ssh"
      agent       = false
      user        = var.gcp_ssh_usr_0
      private_key = var.gcp_ssh_prv_0
      host        = self.network_interface[0].access_config[0].nat_ip
    }
  }

  network_interface {
    network       = "default"
    access_config {
      // any IP
    }
  }

  metadata = {
    
    ssh-keys = join("\n", [
      "${var.gcp_ssh_usr_0}:${var.gcp_ssh_pub_0}",
      "${var.gcp_ssh_usr_1}:${var.gcp_ssh_pub_1}",
      "${var.gcp_ssh_usr_2}:${var.gcp_ssh_pub_2}",
    ])

    gce-container-declaration = yamlencode({
      spec = {
        containers = [{
          image = var.cmp_container_image
        }]
        restartPolicy = "Always"
      }
    })

    # metadata_startup_script = file("${path.module}/scripts/gcp_operator.sh")
  
  }
  
  service_account {
    email  = var.gcp_acc_email_1
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  tags = ["http-server", "https-server", "allow-ssh"]

}

// -------------------------------------------------------------------------------- FIREWALL --- //
// -------------------------------------------------------------------------------- -------- --- //

resource "google_compute_firewall" "allow_ssh" {

  name    = "allow-ssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "8080", "80", "443", "5432"] # ssh, torch, http, https, postgresql
  }

  source_ranges = ["0.0.0.0/0"]  # Allow from any IP, adjust as needed for security
  target_tags   = ["allow-ssh"]

}

