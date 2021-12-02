# BENJOL Terraform and Ansible

This will create the following infrastructure using Terraform:

- Two 1 GB Droplets in the SGP1 datacenter running Ubuntu 20.04
- One DigitalOcean Load Balancer to route HTTP traffic to the Droplets
- One DigitalOcean Cloud Firewall to lock down communication between the Droplets and the outside world
- Domain name server A record

Then use Ansible to run the following tasks on Droplet:

- Update all packages
- Install the DigitalOcean monitoring agent, to enable resource usage graphs in the Control Panel
- Install docker & docker compose
- Set up and run app
