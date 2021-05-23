resource "google_compute_network" "network" {
  name                            = "${var.prefix}-network"
  project                         = var.project
  delete_default_routes_on_create = false
}
resource "google_compute_subnetwork" "subnetwork" {
  name                     = "${var.prefix}-subnetwork"
  network                  = google_compute_network.network.name
  ip_cidr_range            = var.ipcidr_range
  project                  = var.project
  region                   = var.region
  private_ip_google_access = "true"
}
resource "google_compute_router" "router" {
  name    = "${var.prefix}-router"
  region  = var.region
  project = var.project
  network = google_compute_network.network.name
}
resource "google_compute_router_nat" "nat" {
  name                               = "${var.prefix}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  project                            = var.project
  subnetwork {
    name                    = google_compute_subnetwork.subnetwork.self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}
##safe passage to ssh from iap-tunnel
resource "google_compute_firewall" "iap-tunnel" {
  name      = "${var.prefix}-tunnel"
  network   = google_compute_network.network.name
  project   = var.project
  direction = "INGRESS"
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  target_tags   = ["permited-ssh"]
  source_ranges = ["35.235.240.0/20"]
}
resource "google_service_account" "head-chef" {
  account_id   = "head-chef"
  project      = var.project
  display_name = "Chef's Service Account"
}
resource "google_compute_instance" "chef_Workstation" {
  name         = "${var.prefix}-chef-kitchen"
  machine_type = var.machine_type
  project      = var.project
  zone         = var.zone
  tags         = [var.tag]
  boot_disk {
    initialize_params {
      image = var.boot_os
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.subnetwork.self_link
  }

  metadata_startup_script = data.template_file.chef_setup.rendered

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.head-chef.email
    scopes = ["cloud-platform"]
  }
}
data "template_file" "chef_setup" {
  template = file("${path.module}/chef_setup.sh")
  vars = {
    region       = var.region
    zone         = var.zone
    project      = var.project
    machine_type = var.machine_type
    network      = google_compute_network.network.self_link
  }
}