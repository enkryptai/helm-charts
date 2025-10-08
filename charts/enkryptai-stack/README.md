
PENDING: 

1. Opensearch Creation 
2. Database Creation 


kubectl create secret docker-registry core-app-pullsecret -n enkryptai-stack \
  --docker-server=188451452903.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-east-1) 


Provide secret as a parameter during runtime 

aws cloudformation create-stack --stack-name enkryptai-stack \
  --template-body file://sampletemplate.json \
  --parameters \
ParameterKey="AMIId",ParameterValue="MyParameterKey"
