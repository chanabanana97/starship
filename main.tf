provider "aws" {
}
resource "aws_instance" "web_server" {
  ami = "ami-07d8796a2b0f8d29c"
  instance_type = var.instance_type
  vpc_security_group_ids = [ aws_security_group.websg.id ]
  key_name =  aws_key_pair.key_pair.key_name
  user_data = <<-EOF
                #!/bin/bash
                echo "I LOVE TERRAFORM" > index.html
                nohup busybox httpd -f -p 8080 &
                EOF
    tags = {
      Name = "WEB-demo"
    }
  connection {
    type = "ssh"
    user = "ubuntu"
    host = self.public_ip
    private_key = tls_private_key.private_key.private_key_pem
    timeout = "3m"
    }
  provisioner "file" {
    source      = "docker-compose.yml"
    destination = "docker-compose.yml"

}
  provisioner "file" {
    source      = "nginx.conf"
    destination = "nginx.conf"

}
  provisioner "remote-exec" {
    #  download docker and docker-compose automatically at launch of ec2 instance
      inline = [
        "sudo apt -y update",
        "sudo apt-get install -y docker.io",
        "sudo curl -L \"https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)\" -o /usr/local/bin/docker-compose",
        "sudo chmod +x /usr/local/bin/docker-compose",
        "sudo gpasswd -a $USER docker",
        "sudo docker-compose up -d",
        "sudo docker exec -it myvault sh -c 'vault kv put secret/data apikey=4c281f5053fde83d09ea4501a0dcd1ff387b9a3b'",

      ]
  }

}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key_pair" {
  key_name   = "myKey"       # Create a "myKey" to AWS
  public_key = tls_private_key.private_key.public_key_openssh

}

resource "local_file" "key" {
  content = tls_private_key.private_key.private_key_pem # create a "myKey" file locally
  filename = "myKey.pem"
}

resource "aws_security_group" "websg" {
  name = "web-sg01"
  ingress {
    protocol = "tcp"
    from_port = 8080
    to_port = 8080
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol = "tcp"
    from_port = 80
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol = "tcp"
    from_port = 22
    to_port = 22
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }
  egress {
    protocol = "tcp"
    from_port = 80
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]

  }
    egress {
    protocol = "tcp"
    from_port = 443
    to_port = 443
    cidr_blocks = ["0.0.0.0/0"]

  }
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}



output "instance_ips" {
  value = aws_instance.web_server.public_ip
}