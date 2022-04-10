provider "aws" {
}
resource "aws_instance" "tfvm" {
  ami = "ami-07d8796a2b0f8d29c"
  instance_type = var.instance_type
  vpc_security_group_ids = [ aws_security_group.websg.id ]
//  user_data = <<-EOF
//                #!/bin/bash
//                echo "I LOVE TERRAFORM" > index.html
//                nohup busybox httpd -f -p 8080 &
//                EOF
  user_data	= file("file.sh")
    tags = {
      Name = "WEB-demo"
    }
}
resource "aws_security_group" "websg" {
  name = "web-sg01"
  ingress {
    protocol = "tcp"
    from_port = 8080
    to_port = 8080
    cidr_blocks = ["${chomp(data.http.myip.body)}/32"]
  }
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

output "instance_ips" {
  value = aws_instance.tfvm.public_ip
}

