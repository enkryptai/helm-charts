Nice — that’s a solid README draft, but let’s make it **clean, professional, and GitHub-ready** while keeping the instructions crystal clear.
Here’s a polished version with better structure, readable formatting, and developer-friendly language 👇

---

#  EnkryptAI Helm Charts

This repository contains Helm charts for deploying the **EnkryptAI stack** — including the core platform and supporting services — on AWS using **CloudFormation** and **Amazon EKS**.

---

##  Prerequisites

Before installing Helm charts, ensure you have:

* AWS CLI configured (`aws configure`)
* kubectl installed and connected to your EKS cluster
* Helm v3+ installed
* Permissions to create CloudFormation stacks and EKS resources

---

## ☁️ Step 1: CloudFormation Setup

Run the CloudFormation stack **before** installing Helm charts.
This will provision the required AWS infrastructure (EKS, S3, IAM roles, Secret Manager, etc.)

### Files Required

| File             | Description                                                                             |
| ---------------- | --------------------------------------------------------------------------------------- |
| `parameter.json` | Contains environment-specific parameters and secrets *(provided by the EnkryptAI team)* |
| `main.yaml`      | CloudFormation template that creates the infrastructure stack                           |

###  Create Stack

```bash
aws cloudformation create-stack \
  --stack-name enkryptai-stack \
  --template-body file://main.yaml \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --region us-west-2 \
  --parameters file://parameter.json \
  --tags Key=App,Value=enkryptai-stack
```

###  Update Stack

```bash
aws cloudformation update-stack \
  --stack-name enkryptai-stack \
  --template-body file://main.yaml \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --region us-west-2 \
  --parameters file://parameter.json \
  --tags Key=App,Value=enkryptai-stack
```

> **Note:** During initial setup (POC phase), the EnkryptAI team will provide preconfigured files.
> You only need to supply environment-specific values such as your domain name.

---

##  Step 2: Clone the Repository

```bash
git clone https://github.com/enkryptai/helm-charts.git
cd helm-charts
```

Create the target namespace:

```bash
kubectl create namespace enkryptai-stack
```

---

##  Step 3: Available Helm Charts


| Chart                                                   | Description                                                                  |
| ------------------------------------------------------- | ---------------------------------------------------------------------------- |
| [`enkryptai-stack`](./charts/enkryptai-stack/README.md) | Full-stack deployment including all EnkryptAI services                       |
| [`platform`](./charts/platform/README.md)               | Core platform dependencies and shared infrastructure                         |
| [`enkryptai-lite`](./charts/enkryptai-lite/README.md)   | Lightweight deployment — includes Red Teaming and Guardrails components only |

---

## Notes

* Ensure your AWS credentials have sufficient IAM permissions to deploy CloudFormation stacks and access S3.
* If you’re deploying to a non-`us-west-2` region, modify the `--region` flag accordingly.
* For private registries or secret values, update them in `values.yaml` or the provided parameter file.

---

## Support

If you face any issues during deployment, reach out to the **EnkryptAI DevOps Team** or raise a GitHub issue in this repository.

---
