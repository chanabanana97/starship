# create an ec2 instance on AWS using terraform
run webapp app and mongo on the vm with docker

## Installation and preparation
- Install [terraform](https://www.terraform.io/downloads) to your computer
- Create [AWS](https://aws.amazon.com/free/?trk=ebcd9855-a5db-45fc-a89a-6a352ba55e98&sc_channel=ps&sc_campaign=acquisition&sc_medium=ACQ-P|PS-GO|Brand|Desktop|SU|Core-Main|Core|IL|EN|Text&s_kwcid=AL!4422!3!456914465927!e!!g!!aws&ef_id=Cj0KCQjwmPSSBhCNARIsAH3cYgaUJQWFHNp27x9S5TSXim1dkyeLFl4rLGOER51zF-rLxU7k4hpnJEMaApfSEALw_wcB:G:s&s_kwcid=AL!4422!3!456914465927!e!!g!!aws&all-free-tier.sort-by=item.additionalFields.SortRank&all-free-tier.sort-order=asc&awsf.Free%20Tier%20Types=*all&awsf.Free%20Tier%20Categories=*all) account
- [Set environment variables](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html) (**export** for Linux/Mac **set** for Windows)
```
set AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
set AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
set AWS_DEFAULT_REGION=us-west-2
```

## Usage
variables: `instance type` - The instance type to use for the instance. default value = `t2.micro`.
 
to run the code:
 1. `terraform init` -  initialize a working directory containing Terraform configuration files
 2. `terraform plan` - evaluates a Terraform configuration to determine the desired state of all the resources it declares
 3. `terraform apply` - performs a plan just like terraform plan does, but then actually carries out the planned changes to each resource using the relevant infrastructure provider's API.

to terminate the instance when done: `terraform destroy`
 
the **output** of the terraform apply will be the `instance_ips` which you can run locally on your computer to see the app. `'http://<instance_ips>'`

## code architecture

![image](https://user-images.githubusercontent.com/62520653/167911592-4efa5a29-bf13-41bd-a83e-6e69002286b3.png)

### Containers:
- nginx - open source software for web serving, reverse proxying load balancing, and more. serves the _webapp_ on port 80.
- webapp - flask app from image (from rezilion.py) connects to _vault_ and _mongodb_
- mongodb - open source NoSQL database management program. contains data for _webapp_
- vault - Vault secures, stores, and tightly controls access to tokens, passwords, certificates, API keys, and other secrets in modern computing. contains api key for _webapp_.

