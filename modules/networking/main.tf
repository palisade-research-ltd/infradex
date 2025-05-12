
// --- --------------------------------------------------------------------------- NETWORKING --- //
// --- --------------------------------------------------------------------------- ---------- --- //

resource "google_project_service" "enable_apis" {

  for_each = local.apis
  project = var.prj_project_id
  service = "${each.value["url"]}.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false

  timeouts {
    create = "300m"
    update = "300m"
    delete = "300m"
    read   = "300m"
  }

}

