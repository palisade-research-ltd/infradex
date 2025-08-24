
module "networking" {

  source = "../../modules/networking"

  pro_project_id  = var.pro_project_id
  pro_environment = var.pro_environment
  pro_region      = var.pro_region
  pro_zone        = var.pro_zone

}

module "roles" {

  depends_on = [module.networking]

}

module "compute" {

  depends_on = [module.networking, module.roles]

}

module "data" {

  depends_on = [module.networking, module.compute, module.roles]

}

