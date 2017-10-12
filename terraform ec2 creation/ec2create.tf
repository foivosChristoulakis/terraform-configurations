

provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}




resource "aws_instance" "example" {
  ami           = "ami-cd0f5cb6"
  instance_type = "t2.micro"
  
    provisioner "local-exec" {
    command = "echo ${aws_instance.example.public_ip} > ip_address.txt"
  }
  
}

















