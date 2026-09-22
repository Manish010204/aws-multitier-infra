# Multi-Tier AWS Infrastructure with Full Observability

![Terraform](https://img.shields.io/badge/IaC-Terraform_1.10-7B42BC?logo=terraform)
![AWS](https://img.shields.io/badge/Cloud-AWS-FF9900?logo=amazonaws)
![CI](https://github.com/Manish010204/aws-multitier-infra/actions/workflows/terraform-validate.yml/badge.svg)

> Production-grade 3-tier AWS infrastructure built entirely with Terraform — featuring network isolation, auto-scaling, managed database, and automated alerting.

---

## Problem Statement

Most tutorials deploy apps on a single EC2 with a public IP and no monitoring. Real production systems don't work that way.

This project implements a proper 3-tier architecture — the way companies like Swiggy, Razorpay, and Zepto run their infrastructure — with full network isolation between tiers, zero direct internet access to application servers, auto-scaling based on real load, and automated alerting before users notice problems.

---

## Architecture

```
Internet
    |
    v
Application Load Balancer
(Public Subnets - ap-south-1b + ap-south-1c)
    |
    v
Auto Scaling Group - EC2 Nginx
(Private App Subnets - no public IP)
min: 1 | desired: 1 | max: 2
    |
    v
RDS MySQL 8.0
(Private DB Subnets - isolated)
    |
    v
CloudWatch Alarms --> SNS --> Email Alerts
```

---

## What's Built

### Networking (VPC Module)
- Custom VPC `10.0.0.0/16` across 2 Availability Zones
- 6 subnets — Public / Private App / Private DB per AZ
- Internet Gateway for public tier
- NAT Gateway for private tier outbound access
- Route tables with proper tier isolation
- VPC Flow Logs to CloudWatch for network audit trail

### Compute (Compute Module)
- Application Load Balancer in public subnets
- Auto Scaling Group (min 1, max 2) in private subnets
- EC2 t3.micro instances with **zero public IP** — only reachable via ALB
- IAM role with SSM access — no SSH keys, no port 22 open
- Target tracking scaling policy — CPU threshold 70%
- ALB health checks with automatic unhealthy instance replacement

### Database (Database Module)
- RDS MySQL 8.0 in isolated private subnets
- Security group allows **only port 3306 from EC2 security group**
- Encryption at rest enabled (AES-256)
- Automated backups configured

### Monitoring (Monitoring Module)
- SNS topic with confirmed email subscription
- CloudWatch Alarm: EC2 CPU > 70%
- CloudWatch Alarm: ALB 5XX errors > 10/min
- CloudWatch Alarm: ALB response time > 2 seconds
- RDS CPU and free storage alarms

### CI/CD (GitHub Actions)
- Triggers on every push and PR to main branch
- Runs: Format check -> Init -> Validate -> Plan
- AWS credentials stored in GitHub Secrets — never hardcoded

---

## Screenshots

### App Running via ALB (Instance ID + AZ visible)
![App](screenshots/Screenshot%202026-09-22%20145638.png)

### VPC Resource Map (6 subnets, IGW, NAT)
![VPC Resource Map](screenshots/Screenshot%202026-09-22%20144329.png)

### VPC Overview
![VPC](screenshots/Screenshot%202026-09-22%20144257.png)

### All Subnets (Public + Private App + Private DB)
![Subnets](screenshots/Screenshot%202026-09-22%20144426.png)

### Auto Scaling Group - Healthy
![ASG](screenshots/Screenshot%202026-09-22%20142938.png)

### CloudWatch Dashboard
![CloudWatch](screenshots/Screenshot%202026-09-22%20144623.png)

### CloudWatch Alarm Firing
![Alarm](screenshots/Screenshot%202026-09-22%20144736.png)

### SNS Topic - Email Confirmed
![SNS](screenshots/Screenshot%202026-09-22%20144846.png)

### RDS Dashboard
![RDS](screenshots/Screenshot%202026-09-22%20145026.png)

### ALB Target Group
![Target Group](screenshots/Screenshot%202026-09-22%20145212.png)

### Terraform Output
![Terraform Output](screenshots/Screenshot%202026-09-22%20145413.png)

---

## Cost Analysis

Total spent on deploy day: **~Rs 350** (3-4 hours active, destroyed immediately after)

| Resource | Duration | Cost |
|---|---|---|
| EC2 t3.micro x1 | 4 hours | ~Rs 0 (free tier) |
| NAT Gateway | 4 hours | ~Rs 150 |
| RDS db.t3.micro | 4 hours | ~Rs 100 |
| ALB | 4 hours | ~Rs 60 |
| S3 + DynamoDB + SNS | always | Rs 0 (free tier) |
| **Total** | | **~Rs 310-350** |

Infrastructure is destroyed after documentation. Rebuilt anytime in ~15 minutes via `terraform apply`.

---

## Key Design Decisions

| Decision | Why |
|---|---|
| EC2 has no public IP | Only ALB is internet-facing — reduces attack surface |
| EC2 SG references ALB SG | Not CIDR — only the ALB can reach EC2, not the entire subnet |
| RDS SG references EC2 SG | Only app tier reaches DB — defense in depth |
| Single NAT Gateway | Cost saving — two would be HA but doubles NAT cost |
| IAM role on EC2 | Zero hardcoded credentials — AWS auto-rotates temp creds |
| S3 remote state | Safe from laptop crashes, enables team collaboration |
| Modular Terraform | Each concern isolated — easier to debug and reuse |

---

## Project Structure

```
aws-multitier-infra/
├── .github/
│   └── workflows/
│       └── terraform-validate.yml
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── backend.tf
│   ├── versions.tf
│   ├── terraform.tfvars.example
│   └── modules/
│       ├── vpc/
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── compute/
│       │   ├── sg.tf
│       │   ├── iam.tf
│       │   ├── alb.tf
│       │   ├── asg.tf
│       │   ├── user-data.sh
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── database/
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       └── monitoring/
│           ├── main.tf
│           ├── variables.tf
│           └── outputs.tf
├── scripts/
│   └── setup-backend.sh
├── docs/
│   └── cost-analysis.md
├── screenshots/
└── README.md
```

---

## How to Deploy

### Prerequisites
- AWS CLI configured with IAM user credentials
- Terraform >= 1.10.0 installed
- Git

### Step 1 — Create backend (run once)

```bash
bash scripts/setup-backend.sh
```

### Step 2 — Fill your values

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

### Step 3 — Deploy

```bash
cd terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### Step 4 — Destroy when done

```bash
terraform destroy
```

> Always destroy after testing — NAT Gateway and RDS charge by the hour.

---

## Real Errors Hit During Deployment

This project was built and deployed end-to-end, hitting and fixing real production issues:

- **IAM permission gaps** — added missing RDS and CloudWatch policies to IAM user
- **Terraform state lock** — GitHub Actions left a state lock; resolved with `terraform force-unlock`
- **EC2 capacity unavailable** — `t2.micro` unavailable in `ap-south-1a`; switched to `t3.micro`
- **RDS password validation** — `@` character not allowed in RDS passwords; fixed format
- **IMDSv2 metadata** — EC2 user-data needed token-based metadata fetch for newer instances
- **State sync issues** — manual AWS cleanup required after partial apply failures

> These are real production problems. Knowing how to debug and fix them matters more than a clean first run.

---

## Tech Stack

`AWS` `Terraform` `EC2` `ALB` `Auto Scaling Group` `RDS MySQL 8.0` `VPC` `IAM` `CloudWatch` `SNS` `VPC Flow Logs` `GitHub Actions` `Nginx` `Amazon Linux 2023` `Bash`

---

## Author

**Manish Kumar Thakur**

- GitHub: [@Manish010204](https://github.com/Manish010204)
- LinkedIn: [manish-thakur](https://www.linkedin.com/in/manish-thakur-lpu/)
- Email: p2004.manishthakur@gmail.com
