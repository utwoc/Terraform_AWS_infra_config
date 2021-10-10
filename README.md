# Terraform_AWS_infra_config
A Web Server Architecture hosted in AWS using Terraform 

1. Create vpc
2. Create Internet Gateway
3. Create Custom Route Table
4. Create a Subnet 
5. Associate subnet with Route Table
6. Create Security Group to allow port 22,80,443
7. Create a network interface with an ip in the subnet that was created in step 4
8. Assign an elastic IP to the network interface created in step 7
9. Create Ubuntu server and install/enable apache2
