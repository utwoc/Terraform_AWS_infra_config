variable "access_key" {
  description = "Access key"
  type = string
}
variable "secret_key" {
  description = "Secret key"
  type = string
}

provider "aws" {
  region = "ap-south-1"

  access_key = var.access_key
  secret_key = var.secret_key
}



#-------------------------------------Instance------------------
# resource "aws_instance" "Terraform-Server" {
#  ami           = "ami-0c1a7f89451184c8b"
#  subnet_id = "subnet-0fbe8de9f8116ad05"
#  instance_type = "t2.micro"
#  tags = {
#    Name = "ubuntu"
#  }
# }
#-------------------------------------VPC AND SUBNET-----------------
# resource "aws_vpc" "Terraform-VPC" {
#   cidr_block = "10.16.0.0/16"
#   tags = {
#       Name = "terraformvpc"
#   }
# }

# resource "aws_subnet" "Subnet1" {
#   vpc_id     = aws_vpc.Terraform-VPC.id
#   cidr_block = "10.16.1.0/24"

#   tags = {
#     Name = "terraformsubnet1"
#   }
# }
#---------------------------------------------------------------------


resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "PRODUCTION VPC"
  }
}

resource "aws_internet_gateway" "prod-gw" {
  vpc_id = aws_vpc.prod-vpc.id

  tags = {
    Name = "PRODUCTION IGW"
  }
}

resource "aws_route_table" "prod-rt" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.prod-gw.id
    }

  route  {
      ipv6_cidr_block        = "::/0"
      gateway_id = aws_internet_gateway.prod-gw.id
    }

  tags = {
    Name = "PRODUCTION RT"
  }
}

resource "aws_subnet" "subnet-1" {
  vpc_id = aws_vpc.prod-vpc.id
  cidr_block = "10.0.1.0/24"
  #availability_zone = "ap-south-1b"
  tags = {
    Name = "PRODUCTION SUBNET"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-rt.id
}

resource "aws_security_group" "allow_web_traffic" {
  name        = "allow_web"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
      description      = "HTTPS"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  
  ingress {
      description      = "HTTP"
      from_port        = 80 
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  
  ingress  {
      description      = "SSH"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }


  egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }

  tags = {
    Name = "ALLOW WEB TRAFFIC"
  }
}

resource "aws_network_interface" "prod-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web_traffic.id]

}

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.prod-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.prod-gw]
}

resource "aws_instance" "Web-Server" {
 ami           = "ami-0c1a7f89451184c8b"
 instance_type = "t2.micro"
 #availability_zone = "ap-south-1b"
 key_name = "aniket-training"

 network_interface {
   device_index = 0
   network_interface_id = aws_network_interface.prod-nic.id
 }

 user_data = <<-EOF
            #!/bin/bash
            sudo apt update -y
            sudo apt install apache1 -y
            sudo systemctl atsrt apache2
            sudo bash -c 'echo web server > /var/www/html/index.html'
            EOF
  tags = {
    Name = "WEB SERVER"
  }
 
}

output "server_private_ip" {
  value = aws_instance.Web-Server.private_ip
}
output "server_id" {
  value = aws_instance.Web-Server.id
}