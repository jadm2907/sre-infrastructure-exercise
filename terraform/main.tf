provider "google" {
  project = "sre-infrastructure-exercise"
  region  = "us-central1"
}

# VPC (using default VPC)
data "google_compute_network" "default" {
  name = "default"
}

# Firewall Rules (equivalent to Security Groups)
resource "google_compute_firewall" "web" {
  name    = "sre-allow-web"
  network = data.google_compute_network.default.name
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web"]
}

# HTTP Load Balancer (equivalent to Application Load Balancer)
resource "google_compute_instance_template" "web_template" {
  name_prefix  = "sre-web-"
  machine_type = "e2-micro"
  tags         = ["web"]
  disk {
    source_image = "projects/sre-infrastructure-exercise/global/images/sre-webapp-<timestamp>"
  }
  network_interface {
    network = data.google_compute_network.default.name
  }
}

resource "google_compute_instance_group_manager" "web_group" {
  name               = "sre-web-group"
  zone               = "us-central1-a"
  base_instance_name = "sre-web"
  target_size        = 2
  version {
    instance_template = google_compute_instance_template.web_template.id
  }
}

resource "google_compute_http_health_check" "web_health" {
  name               = "sre-web-health"
  request_path       = "/"
  check_interval_sec = 5
  timeout_sec        = 5
}

resource "google_compute_backend_service" "web_backend" {
  name        = "sre-web-backend"
  protocol    = "HTTP"
  health_checks = [google_compute_http_health_check.web_health.id]
  backend {
    group = google_compute_instance_group_manager.web_group.instance_group
  }
}

resource "google_compute_url_map" "web_url_map" {
  name            = "sre-web-url-map"
  default_service = google_compute_backend_service.web_backend.id
}

resource "google_compute_target_http_proxy" "web_proxy" {
  name    = "sre-web-proxy"
  url_map = google_compute_url_map.web_url_map.id
}

resource "google_compute_global_forwarding_rule" "web_forwarding" {
  name       = "sre-web-forwarding"
  target     = google_compute_target_http_proxy.web_proxy.id
  port_range = "80"
}

# Cloud SQL for PostgreSQL (equivalent to RDS)
resource "google_sql_database_instance" "postgres" {
  name             = "sre-postgres"
  database_version = "POSTGRES_15"
  region           = "us-central1"
  settings {
    tier = "db-f1-micro"
  }
}

resource "google_sql_database" "app_db" {
  name     = "app_db"
  instance = google_sql_database_instance.postgres.name
}

# Cloud DNS (equivalent to Route 53 Hosted Zone and Alias)
resource "google_dns_managed_zone" "app_zone" {
  name        = "sre-app-zone"
  dns_name    = "app.example.com."
}

resource "google_dns_record_set" "app_alias" {
  name         = "www.${google_dns_managed_zone.app_zone.dns_name}"
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.app_zone.name
  rrdatas      = [google_compute_global_forwarding_rule.web_forwarding.ip_address]
}