variable "ssh_user" {
  default = "dikshantmali43"
}

variable "project" {
  default = "dikshantnew"
}
variable "cluster_name" {
  default = "tf-gke-pvt-cluster"
}

variable "nat_eip_name"{
    default = "mynetgw-eip"
}

variable "region" {
    default = "us-central1"
}

variable "nat-gw-name" {
  default = "tf-ngw"
}

variable "cloud_router_name" {
  default = "my-cloudrouter"
}
variable "network"{
  default = "tf-gke-vpc"
}

variable "subnetwork"{
  default = "tf-gke-subnet"
}


variable "subnetwork_range"{
  default = "10.20.0.0/16"
}

variable "cluster_zone"{
    default = "us-central1-c"
}
variable "master_cidr"{
  default = "172.16.0.0/28"
}

variable "node_count" {
  default = 1
}

variable "disk_size_gb" {
  default = 50
}


variable "disk_type" {
  default = "pd-standard"
}

variable "machine_type" {
  default = "n2d-standard-4"
}




variable "cluster_secondary_range"{
  default = "10.4.0.0/14"
}

variable "cluster_service_range"{
  default = "10.0.32.0/20"
}
