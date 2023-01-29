provider "aws" {
  region = "us-east-1"
  profile = "jenkins"
}


# SG
resource "aws_security_group" "allow_inbound" {
  name        = "allow_tls"
  description = "Allow inbound traffic"

  dynamic "ingress" {
    for_each = var.ingressrules
    iterator = port
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    ="TCP"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
     }

    tags = {
      Name = "sg"
    }
  }



# key pair 
module "key_pair" {
  source     = "terraform-aws-modules/key-pair/aws"
  key_name   = "jenkins"
  public_key = file(var.public_key)
}


# resource block
resource "aws_instance" "jenkins" {
  ami             = data.aws_ami.redhat.id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.allow_inbound.name]
  key_name        = "jenkins"
  tags = {
    Name = "Jenkins-server"
  }
}


# Domain block 
resource "aws_route53_record" "domainName" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = var.domainName
  type    = "A"
  ttl     = 10
  records = [aws_instance.jenkins.public_ip]
}

# null resource 
resource "null_resource" "os_update" {
  depends_on = [aws_instance.jenkins]
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(var.private_key)
    host        = aws_instance.jenkins.public_ip
    timeout     = "50s"
  }



  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y java-11-openjdk-devel",
      "sudo yum -y install wget",
      "sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo",
      "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key",
      "sudo yum upgrade -y",
      "sleep 10"
    ]
  }
}

# null resource 
resource "null_resource" "install_jenkins" {
  depends_on = [aws_instance.jenkins, null_resource.os_update]
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(var.private_key)
    host        = aws_instance.jenkins.public_ip
    timeout     = "20s"
  }


  provisioner "remote-exec" {
    inline = [
      "sudo yum install jenkins -y",
      "sleep 10",
      "sudo systemctl restart jenkins",
      "sleep 10",
      "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
    ]
  }
}