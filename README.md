# 🏗️ Multi-Tier AWS Infrastructure with Full Observability

![Terraform](https://img.shields.io/badge/IaC-Terraform_1.10-7B42BC?logo=terraform)
![AWS](https://img.shields.io/badge/Cloud-AWS-FF9900?logo=amazonaws)
![CI](https://github.com/Manish010204/aws-multitier-infra/actions/workflows/terraform-validate.yml/badge.svg)

> Production-grade 3-tier AWS infrastructure built entirely with Terraform —
> featuring network isolation, auto-scaling, managed database, and automated alerting.

---

## 📌 Problem Statement

Most tutorials deploy apps on a single EC2 with a public IP and no monitoring.
Real production systems don't work that way.

This project implements a proper 3-tier architecture — the way companies like
Swiggy, Razorpay, and Zepto run their infrastructure — with:
- Full network isolation between tiers
- Zero direct internet access to application servers
- Auto-scaling based on real load
- Automated alerting before users notice problems

---

## 🏗️ Architecture
Internet
↓
Application Load Balancer (Public Subnets — AZ1a + AZ1b)
↓
Auto Scaling Group — EC2/Nginx (Private App Subnets)
min: 1 | desired: 2 | max: 3
↓
RDS MySQL Multi-AZ (Private DB Subnets — isolated)
↓
CloudWatch Alarms → SNS → Email Alerts

---

## ✅ What's Built

### 🌐 Networking (VPC Module)
- Custom VPC `10.0.0.0/16` across 2 Availability Zones
- 6 subnets — Public / Private App / Private DB per AZ
- Internet Gateway for public tier
- NAT Gateway for private tier outbound access
- Route tables with proper tier isolation
- VPC Flow Logs → CloudWatch for network audit trail

### ⚙️ Compute (Compute Module)
- Application Load Balancer in public subnets
- Auto Scaling Group (min 1, max 3) in private subnets
- EC2 instances with **zero public IP** — only reachable via ALB
- IAM role with SSM access — no SSH keys, no port 22
- Target tracking scaling policy — CPU threshold 70%
- ALB health checks with automatic instance replacement

### 🗄️ Database (Database Module)
- RDS MySQL 8.0 in isolated private subnets
- Security group allows **only port 3306 from EC2 SG** — not from internet
- Encryption at rest enabled
- Automated backups configured
- Performance Insights enabled

### 📊 Monitoring (Monitoring Module)
- SNS topic with email subscription
- CloudWatch Alarm: EC2 CPU > 70%
- CloudWatch Alarm: ALB 5XX errors > 10/min
- CloudWatch Alarm: ALB response time > 2s
- RDS CPU and storage alarms

### 🔁 CI/CD (GitHub Actions)
- Triggers on every push and PR to main
- Runs: Format check → Init → Validate → Plan
- AWS credentials via GitHub Secrets — never hardcoded

---

## 💰 Cost Analysis

> Total spent on deploy day: **~₹350** (3-4 hours, destroyed after)

| Resource | Cost |
|---|---|
| EC2 t2.micro ×2 | ~₹0 (free tier) |
| NAT Gateway | ~₹150 |
| RDS db.t3.micro | ~₹100 |
| ALB | ~₹60 |
| S3 + DynamoDB + SNS | ₹0 (free tier) |
| **Total** | **~₹310–350** |

Infrastructure is destroyed after documentation.
Rebuilt anytime in ~15 minutes via `terraform apply`.

---

## 🔑 Key Design Decisions

| Decision | Why |
|---|---|
| EC2 has no public IP | Only ALB is internet-facing — reduces attack surface |
| EC2 SG references ALB SG | Not CIDR — only ALB can reach EC2, not entire subnet |
| RDS SG references EC2 SG | Only app tier can reach DB — defense in depth |
| Single NAT Gateway | Cost saving — two would be HA but doubles NAT cost |
| IAM role on EC2 | Zero hardcoded credentials — auto-rotating temp creds |
| S3 remote state | Safe from laptop crashes, enables team collaboration |
| Modular Terraform | Each concern isolated — easier to debug and reuse |

---

## 📁 Project Structure
aws-multitier-infra/
├── .github/workflows/
│ └── terraform-validate.yml # CI pipeline
├── terraform/
│ ├── main.tf # Root — calls all modules
│ ├── variables.tf # Input variable definitions
│ ├── outputs.tf # Output values after apply
│ ├── backend.tf # S3 remote state config
│ ├── versions.tf # Provider version constraints
│ ├── terraform.tfvars # Values (gitignored)
│ └── modules/
│ ├── vpc/ # Networking layer
│ ├── compute/ # ALB + ASG + EC2
│ │ ├── sg.tf # Security groups
│ │ ├── iam.tf # IAM role + profile
│ │ ├── alb.tf # Load balancer
│ │ └── asg.tf # Auto scaling
│ ├── database/ # RDS MySQL
│ └── monitoring/ # SNS + CloudWatch
├── scripts/
│ └── setup-backend.sh # One-time backend setup
├── docs/
│ └── cost-analysis.md
└── screenshots/ # Deploy day proof

---

## 🚀 How to Deploy

### Prerequisites
- AWS CLI configured (`aws configure`)
- Terraform >= 1.10.0
- An AWS account

### Deploy

```bash
# 1. Create backend (run once)
bash scripts/setup-backend.sh

# 2. Copy and fill your values
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform.tfvars with your values

# 3. Init + Plan + Apply
cd terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### Destroy (always do this after testing!)

```bash
terraform destroy
```

---

## 📸 Screenshots

> See `/screenshots` folder for full deployment proof.

- VPC with all subnets across 2 AZs
- ALB routing traffic — different AZ on each refresh
- Auto Scaling Group activity log
- RDS in isolated private subnet
- CloudWatch dashboard and alarms
- SNS email alert received

---

## 🎥 Demo

> Coming soon — Loom video walkthrough

---

## 🛠️ Tech Stack

`AWS` `Terraform` `EC2` `ALB` `Auto Scaling`
`RDS MySQL` `VPC` `IAM` `CloudWatch` `SNS`
`GitHub Actions` `Nginx` `Linux`

---

## 👤 Author

**Manish Kumar Thakur**
- GitHub: [@Manish010204](https://github.com/Manish010204)
- LinkedIn: [manish-thakur](https://linkedin.com/in/manish-thakur)
- Email: p2004.manishthakur@gmail.com