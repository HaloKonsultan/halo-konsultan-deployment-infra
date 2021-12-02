variable "do_token" { }

variable "ssh_fingerprint" {}

variable "pvt_key_loc" {}

variable "pub_key_loc" {}

provider "digitalocean" {
  token = var.do_token
}

# create droplet
resource "digitalocean_droplet" "halokonsultan-s1" {
  image    = "ubuntu-20-04-x64"
  name     = "halokonsultan-s1"
  region   = "sgp1"
  size     = "s-1vcpu-1gb"
  ssh_keys = [var.ssh_fingerprint]

  connection {
    host        = self.ipv4_address
    type        = "ssh"
    user        = "root"
    private_key = file(var.pvt_key_loc)
  }

  provisioner "local-exec" {
    command = "echo '${digitalocean_droplet.halokonsultan-s1.name} ansible_host=${digitalocean_droplet.halokonsultan-s1.ipv4_address} ansible_ssh_user=root ansible_python_interpreter=/usr/bin/python3' > inventory"
  }

  provisioner "local-exec" {
    command = "sleep 10 && ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ${self.ipv4_address}, --private-key ${var.pvt_key_loc} -e pub_key=${var.pub_key_loc} ansible.yml"
  }
}

# create a loadbalancer
#resource "digitalocean_loadbalancer" "halokonsultan-lb" {
#  name   = "halokonsultan-lb"
#  region = "sgp1"

#  droplet_ids = [
#    digitalocean_droplet.halokonsultan-s1.id,
#  ]

#  forwarding_rule {
#    entry_port     = 80
#    entry_protocol = "http"

#    target_port     = 80
#    target_protocol = "http"
#  }
#}

# create a firewall that only accepts port 80 traffic from the load balancer
resource "digitalocean_firewall" "halokonsultan-firewall" {
  name = "halokonsultan-firewall"

  droplet_ids = [
    digitalocean_droplet.halokonsultan-s1.id,
  ]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0"]
  }
  inbound_rule {
    protocol                  = "tcp"
    port_range                = "80"
    #source_load_balancer_uids = [digitalocean_loadbalancer.halokonsultan-lb.id]
    source_addresses = ["0.0.0.0/0"]
  }
  inbound_rule {
    protocol                  = "tcp"
    port_range                = "443"
    #source_load_balancer_uids = [digitalocean_loadbalancer.halokonsultan-lb.id]
    source_addresses = ["0.0.0.0/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "all"
    destination_addresses = ["0.0.0.0/0"]
  }
  outbound_rule {
    protocol              = "udp"
    port_range            = "all"
    destination_addresses = ["0.0.0.0/0"]
  }
}

# create record to the domain

resource "digitalocean_domain" "default" {
    name = "halokonsultan.me"
}

resource "digitalocean_record" "www" {
    domain = digitalocean_domain.default.name
    type   = "A"
    name   = "@"
    value  = digitalocean_droplet.halokonsultan-s1.ipv4_address
}

resource "digitalocean_record" "api" {
    domain = digitalocean_domain.default.name
    type   = "A"
    name   = "api"
    value  = digitalocean_droplet.halokonsultan-s1.ipv4_address
}


# create an ansible inventory file

# output the load balancer ip
#output "ip_lb" {
#  value = digitalocean_loadbalancer.halokonsultan-lb.ip
#}

# output the server ip
output "ip_s1" {
  value = digitalocean_droplet.halokonsultan-s1.ipv4_address
}

# Output the FQDN for the www A record.
output "www_fqdn" {
  value = digitalocean_record.www.fqdn
}

# Output the FQDN for the api A record.
output "api_fqdn" {
  value = digitalocean_record.api.fqdn
}
