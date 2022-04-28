#____________________Networking starts__________________
# Make vpc in GCP

resource "google_compute_network" "vpc_network" {
  project                 = var.project
  name                    = var.network
  auto_create_subnetworks = false
  mtu                     = 1460
}


# below resource add subnet to the VPC

resource "google_compute_subnetwork" "my_subnet" {
  project       = var.project
  name          = var.subnetwork
  ip_cidr_range = var.subnetwork_range
  region        = var.region
  network       = google_compute_network.vpc_network.id
}


# we will access k8s master using Jump host means by a specific IP
# below is the firewall rule for that jump host

resource "google_compute_firewall" "allow-nodes" {
  name    = "tf-fw-allow"
  project = var.project
  network = google_compute_network.vpc_network.id
  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  source_ranges = ["10.20.0.0/16"]
}

# create external IP for NAT gateway 

resource "google_compute_address" "mynat" {
  name = var.nat_eip_name
}

# lets create a cloud router so that NATgateway can later utilize it

resource "google_compute_router" "router" {
  name    = var.cloud_router_name
  project = var.project
  region  = var.region
  network = google_compute_network.vpc_network.id
}

# create NAT gateway to be utilized by pvt nodes of cluster so that they can utlize
# or pull docker repo or any dependency from internet

resource "google_compute_router_nat" "nat" {
  name                               = var.nat-gw-name
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = [google_compute_address.mynat.self_link]
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  
  subnetwork {
    name = google_compute_subnetwork.my_subnet.self_link
    source_ip_ranges_to_nat = ["PRIMARY_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}



#________________The networking part ends here_______________________



#------------------let's start the cluster creation part---------------


resource "google_container_cluster" "cluster" {
  name               = var.cluster_name

## Add location for multi AZ worker nodes
#location           = var.region

  location           = var.cluster_zone
  project            = var.project
  network            = google_compute_network.vpc_network.self_link
  subnetwork         = google_compute_subnetwork.my_subnet.self_link
  remove_default_node_pool = "true"
  initial_node_count       = 1

  
  ip_allocation_policy{
    
  }

  private_cluster_config {
    # make below option false if u want to use  master_authorized_networks_config option with
    # your own public ip so that only this public ip can connect to it...falsing below option allow
    # connection using both private and end point of cluster
    enable_private_endpoint = false
    enable_private_nodes = true
    master_ipv4_cidr_block = var.master_cidr
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }
  }


  master_authorized_networks_config {
    cidr_blocks {
      cidr_block = "157.119.213.251/32"
    }
  }

}
resource "google_container_node_pool" "mynodepool" {
  cluster      = google_container_cluster.cluster.name
#Add region for multi AZ worker nodes terraform will auto detect and make cluster regional
  location     = var.cluster_zone
  project      = var.project
  name    = "tf-nodepool"
  node_count = var.node_count
  node_config {
    preemptible  = true
    disk_size_gb = var.disk_size_gb
    disk_type    = var.disk_type
    machine_type = var.machine_type
    
  }
 
  depends_on = [google_container_cluster.cluster]
}


# configure anthos for gcp using provisioner in null resource

 resource "null_resource" "myns" {
  
   depends_on = [
     google_container_node_pool.mynodepool
   ]
  triggers = {
    always_run = "${timestamp()}"
  }

   provisioner "local-exec" {
    working_dir = "/home/unthinkable-lap-0258/Desktop/terraform/gcppractice-tf/gcp-pvt-gke-cluster"
    interpreter = [
      "/bin/bash"
    ]
    command = "./script.sh"
  
  }
}

#-------------------cluster creation ends here-------------------------


#-------------------let's make jump host-------------------------------

# resource "google_compute_instance" "launch_instance"{
#   name         = "tf-gke-access-vm"
#   machine_type = "e2-medium"
#   zone         = "us-central1-a"

#   tags = ["ssh"]

#   boot_disk {
#     auto_delete = true
#     device_name = "my-disk"
#     initialize_params {
#       image = "ubuntu-os-cloud/ubuntu-2004-lts"
#       size = 30
#       type = "pd-ssd"
#     }
#   }

#     network_interface {
#     network = google_compute_network.vpc_network.id
#     subnetwork = google_compute_subnetwork.my_subnet.id
   

#     access_config {
#       // Ephemeral public IP
#     }
#   }

#     metadata = {
#     ssh-keys = "${var.ssh_user}:${file("mykey.pub")}"
#   }

 
#  provisioner "remote-exec" {
#     connection {
#       host        = google_compute_instance.launch_instance.network_interface.0.access_config.0.nat_ip  
#       type        = "ssh"
#       user        = var.ssh_user
#       private_key = file("mykey.pem")
#     }
#     inline = [
#       "sudo apt update",
#       "date",
#       "pwd",
#     ]
#   }
  


  
#   }



#-------------------jump host config end-------------------------------