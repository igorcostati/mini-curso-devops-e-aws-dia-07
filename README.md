# Mini Curso DevOps e AWS - Dia 05

Infraestrutura EKS com Karpenter auto-scaling, Kafka (Strimzi) e aplicações Node.js usando Terraform.

## Pré-requisitos

- AWS CLI configurado
- Terraform >= 1.0
- kubectl instalado
- Docker instalado
- eksctl instalado

## Como Executar

### 1️⃣ Criar Cluster EKS (sem Karpenter)

```bash
cd terraform/main-stack
terraform init
terraform plan
terraform apply
```

**O que é criado:**
- VPC (4 subnets em 2 AZs)
- EKS Cluster v1.31 com 2 nós t3.medium
- OIDC provider
- ECR repositories

**Tempo:** ~20 minutos

### 2️⃣ Instalar Karpenter (depois que o cluster estiver pronto)

```bash
terraform apply -var="enable_karpenter=true"
```

**O que é criado:**
- CRDs (NodeClaim, EC2NodeClass, NodePool)
- Karpenter controller (Helm)
- IAM Role para Karpenter
- NodePool configurado em us-east-1a/b

**Tempo:** ~5 minutos

## Validação

```bash
# Verificar Karpenter rodando
kubectl get pods -n kube-system | grep karpenter

# Verificar NodePool
kubectl get nodepool

# Testar auto-scaling
kubectl create deployment nginx --image=nginx --replicas=10
kubectl get nodes -w
```

## Destruir

```bash
# Desabilitar Karpenter primeiro
terraform apply -var="enable_karpenter=false" -auto-approve

# Depois destruir tudo
terraform destroy
```

### ⚠️ Problema com Finalizers

Se o `terraform destroy` travar com erro de timeout no EC2NodeClass, execute:

```bash
# 1. Deletar workloads que usam nodes do Karpenter
kubectl delete deployment nginx -n default  # Se houver

# 2. Deletar NodePools (remove nodes provisionados)
kubectl delete nodepool --all

# 3. Aguardar NodeClaims serem removidos
kubectl get nodeclaim -w  # Ctrl+C quando vazio

# 4. Remover finalizer manualmente
kubectl patch ec2nodeclass default -p '{"metadata":{"finalizers":null}}' --type=merge

# 5. Tentar novamente
terraform destroy -var="enable_karpenter=true"
```

**Ordem correta:** Workloads → NodePools → NodeClaims → Terraform destroy

## Notas

- `enable_karpenter=true`: Habilita CRDs, Controller e NodePool
- `enable_karpenter=false`: Desabilita (padrão)
- NodePool padrão: on-demand, zonas us-east-1a/b, instance types t/m
- Edit `manifests/karpenter.node-pool.yml` para customizar

## 3️⃣ Instalar Kafka (Strimzi)

```bash

# Criar o namespace para o kafka e instalar o strimzi: https://strimzi.io/quickstarts/

kubectl create namespace kafka

kubectl create -f 'https://strimzi.io/install/latest?namespace=kafka' -n kafka

# Antes de fazer a criação do cluster do kafka, criar o IAM Service Account:

eksctl create iamserviceaccount \
        --name ebs-csi-controller-sa \
        --namespace kube-system \
        --cluster labs-dvn-mini-curso-devops-e-aws-eks-cluster \
        --role-name AmazonEKS_EBS_CSI_DriverRole \
        --role-only \
        --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
        --approve

# Instalar o add-on do ebs-csi:

eksctl create addon --cluster labs-dvn-mini-curso-devops-e-aws-eks-cluster \
    --name aws-ebs-csi-driver --version latest \
    --service-account-role-arn arn:aws:iam::273444517440:role/AmazonEKS_EBS_CSI_DriverRole --force

    #Se der erro:

helm install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver -n kube-system --set controller.serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=arn:aws:iam::273444517440:role/AmazonEKS_EBS_CSI_DriverRole

# Criar o cluster do kafka

kubectl apply -f manifests/kafka.cluster.yml -f manifests/kafka.controller.yml -f manifests/kafka.broker.yml -n kafka

# Pega o IP do svc do kafka para colocar na aplicação de testes

kubectl get svc -n kafka

# Build das aplicações
#testar o kafka
docker build -f node-api-consumer/Dockerfile -t 273444517440.dkr.ecr.us-east-1.amazonaws.com/labs-dvn-repo/strimzi/consumer:v2.0 node-api-consumer/

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 273444517440.dkr.ecr.us-east-1.amazonaws.com

docker push 273444517440.dkr.ecr.us-east-1.amazonaws.com/labs-dvn-repo/strimzi/consumer:v2.0

docker build -f node-api-producer/Dockerfile -t 273444517440.dkr.ecr.us-east-1.amazonaws.com/labs-dvn-repo/strimzi/producer:v2.0 node-api-producer/
 
docker push 273444517440.dkr.ecr.us-east-1.amazonaws.com/labs-dvn-repo/strimzi/producer:v2.0

#testar ALB

docker build -f backend/YoutubeLiveApp/Dockerfile -t 273444517440.dkr.ecr.us-east-1.amazonaws.com/labs-dvn-repo/dev/backend:v2.0 backend/

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 273444517440.dkr.ecr.us-east-1.amazonaws.com

docker push 273444517440.dkr.ecr.us-east-1.amazonaws.com/labs-dvn-repo/dev/backend:v2.0

aws eks update-kubeconfig --region us-east-1 --name labs-dvn-mini-curso-devops-e-aws-eks-cluster

# Criar deployment

 kubectl apply -f manifests/consumer.yml -f manifests/producer.yml -n kafka

 # Testar o kafka

  kubectl run nginx --image nginx

  kubectl exec -it nginx -- curl -X POST -H "Content-type: application/json" -d '{"topic": "devops-topic", "message": "Que aula!"}' http://10.0.0.133:3000/send/

  kubectl exec -it nginx -- curl -X GET -H "Content-type: application/json" http://10.0.0.168:3000/consume?topic="devops-topic"

  kubectl logs -n kafka -f consumer-7645c4f5fb-x94st


   while true; sleep 1; do kubectl exec -it nginx -- curl -X POST -H "Content-type: application/json" -d '{"topic": "devops-topic", "message": "Que aula!"}' http://10.0.0.133:3000/send/; done;

```

## Destruir Recursos

### 1. Limpar recursos Kubernetes (criados manualmente)

```bash
# Deletar pod nginx de teste
kubectl delete pod nginx --ignore-not-found=true

# Deletar deployments (producer/consumer)
kubectl delete deployment -n kafka --all --ignore-not-found=true

# Deletar Kafka cluster
kubectl delete kafka -n kafka --all --ignore-not-found=true

# Aguardar um pouco
sleep 10

# Deletar namespace kafka (remove tudo dentro)
kubectl delete namespace kafka --grace-period=30
```

### 2. Destruir infraestrutura Terraform

```bash
cd terraform/main-stack

# Desabilitar Karpenter primeiro
terraform apply -var="enable_karpenter=false" -auto-approve

# Destruir tudo
terraform destroy
```
