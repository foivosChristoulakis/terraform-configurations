
provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}

data "aws_ecs_task_definition" "latestTaskDefinition"{
	 task_definition = "${var.taskDefinition}"
}
#-------------------------------------

resource "aws_security_group" "webserver_tr" {
  name        = "webserver_tr"
  description = "for webservers"
 

  # HTTPS access from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    # HTTP access from anywhere
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
    # HTTP access from anywhere
  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # allow all outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ssh_tr" {
  name        = "ssh_tr"
  description = "for ssh sessions"
 

  # HTTPS access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # allow all outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ecs cluster
resource "aws_ecs_cluster" "web-servers-cluster" {
  name = "web-servers-cluster"
}

# 1st web server
resource "aws_instance" "WS1" {
  tags { Name = "${var.ec2Instance1Name}" }
  ami           = "${var.webServerAMI}"
  instance_type = "${var.webServerInstanceType}"
  availability_zone = "eu-west-2a"
  #security_groups = ["${aws_security_group.webserver_tr.id}","${aws_security_group.ssh_tr.id}"]
  security_groups = ["ssh","webserver"]
  iam_instance_profile = "ecsInstanceRole"
  user_data = "${file("joinClusterScript.txt")}"
  key_name="${var.KeyPairName}"
}

# 2nd web server
resource "aws_instance" "WS2" {
  tags { Name = "${var.ec2Instance2Name}" }
  ami           = "${var.webServerAMI}"
  instance_type = "${var.webServerInstanceType}"
  availability_zone = "eu-west-2b"
  #security_groups = ["${aws_security_group.webserver_tr.id}","${aws_security_group.ssh_tr.id}"]
  security_groups = ["ssh","webserver"]
  iam_instance_profile = "ecsInstanceRole"  
  user_data = "${file("joinClusterScript.txt")}"
  key_name="${var.KeyPairName}"
}
  
# load balancer
resource "aws_elb" "theElb" {
  name               = "elb-for-webservers"
  availability_zones = ["eu-west-2a", "eu-west-2b"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  listener {
    instance_port      = 443
    instance_protocol  = "https"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "arn:aws:iam::754250089381:server-certificate/myCert2"
  }

  health_check {
    healthy_threshold   = 10
    unhealthy_threshold = 2
    timeout             = 5
    target              = "TCP:80"
    interval            = 30
  }

  instances                   = ["${aws_instance.WS1.id}",													"${aws_instance.WS2.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 60

  security_groups = ["sg-527c633b"]
  
}

# service
resource "aws_ecs_service" "cluster" {
  name            = "${var.serviceName}"
  cluster         = "${aws_ecs_cluster.web-servers-cluster.id}"
  task_definition = "${var.taskDefinition}:${data.aws_ecs_task_definition.latestTaskDefinition.revision}"
  desired_count   = 2
  iam_role        = "ecsServiceRole"
 
 placement_strategy {
    type  = "spread"
    field = "instanceId"
  }

  placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  load_balancer {
    elb_name       = "${aws_elb.theElb.name}"
    container_name = "container1"
    container_port = 80
  }


  deployment_maximum_percent = "100"
  deployment_minimum_healthy_percent = "30"
}


# OUTPUTS -------------------------------------------------

output "elb_dns_name"{
	value = "${aws_elb.theElb.dns_name}"
}

output "task_latest_rev"{
	value = "${data.aws_ecs_task_definition.latestTaskDefinition.revision}"
}








