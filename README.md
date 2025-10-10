# Installation

## Clone the repository

```sh 
git clone https://github.com/enkryptai/helm-charts.git
```

Kindly run Cloudformation stack first to create a cluster with the provided parameter.json file. `Parameter.json`  will be provided to you by Enkryptai team

1. CloudFormation stack.

For Cloudformation installation below file are needed. For initial Setup(POC Enkryptai will provide this)

Don’t forget to change DomainName and resend config in parameter.json

1. parameter.json: Consist of all environment variables and secrets.  
2. main.yaml:  Consist of Cloudformation infrastructure code which will create EKS, S3, Secret manager, IAM roles and policies.

## Note: `ENKRYPTAI_LITE_MODE: "true"` will install enkryptai-lite chart. If you want to install enkryptai-stack kindly pass `ENKRYPTAI_LITE_MODE: "false"` in parameter.json 

```sh

# Create stack using below command

aws cloudformation create-stack   \
--stack-name enkryptai-stack   \
--template-body file://main.yaml \
--capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
--region us-west-2  \
--parameters file://../vanguard.json  \
--tags Key=App,Value=enkryptai-stack

# Update Stack using below command
aws cloudformation update-stack   \
--stack-name enkryptai-stack   \
--template-body file://main.yaml \
--capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
 --region us-west-2  \
--parameters file://../vanguard.json  \
--tags Key=App,Value=enkryptai-stack
```



```sh
kubectl create ns enkryptai-stack
```
## Step-1: Platform chart installation 

```sh 
cd charts/platform/
helm dependency update 
helm upgrade --install platform -n enkryptai-stack -f ./values.yaml 
```

## Step-2: Enkryptai-stack installation 

```
cd ./charts/enkryptai-stack/
helm dependency update 
helm upgrade --install enkryptai -n enkryptai-stack -f ./values.yaml 
```


