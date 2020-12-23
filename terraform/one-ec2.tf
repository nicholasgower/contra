
# Paste these three secrets into bash from https://atc-ad.awsapps.com/start#/ :
# export AWS_ACCESS_KEY_ID=...
# export AWS_SECRET_KEY_ID=...
# export AWS_SESSION_TOKEN=...
# and also:
# export AWS_DEFAULT_REGION=us-east-1
variable "ssh_public_key_path" {
  default = "/Users/morsed/.ssh/contradb-terraform.pub"
}
variable "ssh_private_key_path" {
  default = "/Users/morsed/.ssh/contradb-terraform"
}

provider "aws" {}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "contradb" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.nano"
  key_name = aws_key_pair.contradb_terraform.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  subnet_id = aws_subnet.subnet-uno.id

  tags = {
    Name = "contradb"
  }

#   connection {
#     type = "ssh"
#     host = self.public_ip
#     user = "ec2-user"
#     private_key = file(var.ssh_private_key_path)
#   }

#   provisioner "remote-exec" {
#     inline = ["echo hello world"]
#   }

  # delete_on_termination = eventually false, but for now true is aok
  # might need a aws_network_interface, but probably can get away with the network_interface block
}

resource "aws_key_pair" "contradb_terraform" {
  key_name   = "contradb-terraform-key"
  public_key = file(var.ssh_public_key_path)
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow ssh inbound traffic"
  vpc_id = aws_vpc.the-vpc.id

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_vpc" "the-vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
}

resource "aws_eip" "ip-test-env" {
  instance = aws_instance.contradb.id
  vpc = true
}

resource "aws_subnet" "subnet-uno" {
  cidr_block = cidrsubnet(aws_vpc.the-vpc.cidr_block, 3, 1)
  vpc_id = aws_vpc.the-vpc.id
  availability_zone = "us-east-1a"
}
resource "aws_route_table" "route-table-test-env" {
  vpc_id = aws_vpc.the-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.test-env-gw.id
  }
}
resource "aws_route_table_association" "subnet-association" {
  subnet_id      = aws_subnet.subnet-uno.id
  route_table_id = aws_route_table.route-table-test-env.id
}

resource "aws_internet_gateway" "test-env-gw" {
  vpc_id = aws_vpc.the-vpc.id
}

output "ip" {
  value = aws_eip.ip-test-env.public_ip
}
output "domain" {
  value = aws_eip.ip-test-env.public_dns
}
