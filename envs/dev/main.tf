
// --- --------------------------------------------------------------------------- NETWORKING --- //
// --- --------------------------------------------------------------------------- ---------- --- //

module "networking" {

  source = "../../modules/networking"

  prj_project_id  = var.prj_project_id
  prj_environment = var.prj_environment
  prj_region      = var.prj_region
  prj_zone        = var.prj_zone

}

// --- ------------------------------------------------------------------------------ COMPUTE --- //
// --- ------------------------------------------------------------------------------ ------- --- //

module "compute" {

  source = "../../modules/compute/"

  prj_project_id  = var.prj_project_id
  prj_environment = var.prj_environment
  prj_region      = var.prj_region
  prj_zone        = var.prj_zone

  cmp_instance_name   = var.cmp_instance_name
  cmp_instance_image  = var.cmp_instance_image
  cmp_instance_type   = var.cmp_instance_type
  cmp_container_image = var.cmp_container_image

  gcp_acc_email_1 = var.gcp_acc_email_1

  gcp_ssh_usr_0 = var.gcp_ssh_usr_0
  gcp_ssh_pub_0 = var.gcp_ssh_pub_0
  gcp_ssh_prv_0 = var.gcp_ssh_prv_0

  gcp_ssh_usr_1 = var.gcp_ssh_usr_1
  gcp_ssh_pub_1 = var.gcp_ssh_pub_2

  gcp_ssh_usr_2 = var.gcp_ssh_usr_2
  gcp_ssh_pub_2 = var.gcp_ssh_pub_2

  depends_on = [module.networking]

}

