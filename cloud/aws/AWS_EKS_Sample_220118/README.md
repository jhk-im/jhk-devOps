# AWS EKS Sample

## aws eks settings

### 0.bastion settings

### 1. install

```zsh
# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install 
aws --version

# aws cli configure 설정
# AWS Access Key ID [None]: ~~~
# AWS Secret Access Key [None]: ~~~
# Default region name [None]: ap-northeast-2
# Default output format [None]: json

# kubectl
curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/linux/amd64/kubectl
chmod +x ./kubectl
mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$PATH:$HOME/bin
echo 'export PATH=$PATH:$HOME/bin' >> ~/.bashrc
kubectl version --short --client

# eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version

# istioctl 설치
curl -sL https://istio.io/downloadIstioctl | sh -
cp ~/.istioctl/bin/istioctl ~/bin

# IAM Policy
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.3.1/docs/install/iam_policy.json
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

# HELM
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
helm repo add eks https://aws.github.io/eks-charts
```

### 2. cluster 생성

```zsh
# eks cluster 생성
eksctl create cluster \
--version 1.21 \
--name eks-sample \
--node-private-networking \
--region ap-northeast-2 \
--node-type t3.medium \
--nodes 2 \
--with-oidc \
--ssh-access \
--ssh-public-key eks-sample-key \
--managed

# cluster 생성 확인
kubectl get nodes -o wide

# bastion 서버에서만 k8s에 명령을 내릴 수 있도록
eksctl utils update-cluster-endpoints --cluster=eks-sample --private-access=true --public-access=true --approve

# 0.0.0.0 -> bastion server ip
eksctl utils set-public-access-cidrs --cluster=eks-sample 0.0.0.0/32 --approve
```

### 3. istio 설치

```zsh
cat > istio-operator.yaml << EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: istiocontrolplane
spec:
  profile: default
  components:
    egressGateways:
    - name: istio-egressgateway
      enabled: true
      k8s:
        hpaSpec:
          minReplicas: 2
    ingressGateways:
    - name: istio-ingressgateway
      enabled: true
      k8s:
        hpaSpec:
          minReplicas: 2
    pilot:
      enabled: true
      k8s:
        hpaSpec:
          minReplicas: 2
  meshConfig:
    enableTracing: true
    defaultConfig:
      holdApplicationUntilProxyStarts: true
    accessLogFile: /dev/stdout
    outboundTrafficPolicy:
      mode: REGISTRY_ONLY
EOF

istioctl install -f istio-operator.yaml

kubectl get pods -n istio-system

# istio가 자동으로 application 배포 할 때 envoy sidecar proxy 주입 설정
# default namespace 에 배포하는 서비스에는 istio-proxy가 sidecar 로 같이 올라가서 traffic management, security 등 다양한 Istio 의 기능을 사용
kubectl create namespace istio-sample
kubectl label namespace istio-sample istio-injection=enabled
```

### 4. ALB 연결

```zsh
# 0000 -> account id
eksctl create iamserviceaccount \
  --cluster=eks-sample \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::0000:policy/AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --approve

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=eks-sample \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set image.repository=602401143452.dkr.ecr.ap-northeast-2.amazonaws.com/amazon/aws-load-balancer-controller

kubectl get deployment -n kube-system aws-load-balancer-controller

# istio port 반환
kubectl get service istio-ingressgateway -n istio-system -o jsonpath='{.spec.ports[?(@.name=="status-port")].nodePort}'

cat > istio-operator-alb.yaml << EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: istiocontrolplane
spec:
  profile: default
  components:
    egressGateways:
    - name: istio-egressgateway
      enabled: true
      k8s:
        hpaSpec:
          minReplicas: 1
    ingressGateways:
    - name: istio-ingressgateway
      enabled: true
      k8s:
        hpaSpec:
          minReplicas: 1
        service:
          type: NodePort # ingress gateway 의 NodePort 사용
        serviceAnnotations:  # Health check 관련 정보
          alb.ingress.kubernetes.io/healthcheck-path: /healthz/ready
          alb.ingress.kubernetes.io/healthcheck-port: "0000" # 위에서 얻은 port number를 사용
    pilot:
      enabled: true
      k8s:
        hpaSpec:
          minReplicas: 2
  meshConfig:
    enableTracing: true
    defaultConfig:
      holdApplicationUntilProxyStarts: true
    accessLogFile: /dev/stdout
    outboundTrafficPolicy:
      mode: REGISTRY_ONLY
EOF

istioctl install -f istio-operator-alb.yaml

# ALB 생성
cat > kube-ingress.yaml << EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ingress-alb
  namespace: istio-system
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/certificate-arn: "arn:aws:acm:ap-northeast-2:93163~~~~"
    alb.ingress.kubernetes.io/actions.ssl-redirect: '{"Type": "redirect", "RedirectConfig": { "Protocol": "HTTPS", "Port": "443", "StatusCode": "HTTP_301"}}'
spec:
  rules:
  - http:
      paths:
        - path: /*
          backend:
            serviceName: ssl-redirect
            servicePort: use-annotation
        - path: /*
          backend:
            serviceName: istio-ingressgateway
            servicePort: 80
EOF
kubectl apply -f kube-ingress.yaml
```

### 5. test ingress 배포

```zsh
# test ingress 배포
cat > test_pod.yaml << EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: istio-sample
  name: deployment-2048
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: app-2048
  replicas: 1
  template:
    metadata:
      labels:
        app.kubernetes.io/name: app-2048
    spec:
      containers:
      - image: public.ecr.aws/l6m2t8p7/docker-2048:latest
        imagePullPolicy: Always
        name: app-2048
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  namespace: istio-sample
  name: service-2048
spec:
  ports:
    - port: 80
      targetPort: 80
      protocol: TCP
  type: NodePort
  selector:
    app.kubernetes.io/name: app-2048
EOF

kubectl apply -f test_pod.yaml
```

### 6. istio gateway

```zsh

cat > istio-vs-gw.yaml << EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  namespace: istio-sample
  name: sample-virtualservice
spec:
  hosts:
  - "*"
  gateways:
  - ample-gateway

  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: service-2048
        port:
          number: 80
---
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  namespace: istio-sample
  name: sample-gateway
spec:
  selector:
    istio: ingressgateway # use istio default controller
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
---
EOF

kubectl apply -f istio-vs-gw.yaml
```

### Dashboard

```zsh
#1. Aws Cloud9 create environment
#2. Name / Description 작성
#3. Create and run in remote server (SSH connection) 선택
#4. user: ec2-user / host: 3.38.87.41 / port: 22
#5. copy key to clipboard

#6. sh
# key 등록
# 마지막 줄에 5번에서 복사한 key 붙여넣기
vim ~/.ssh/authorized_keys

# nvm 설치
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
. ~/.nvm/nvm.sh
nvm install node

#7. cloud9 next step

#8. k8s dashboard 설치 / 실행
export DASHBOARD_VERSION="v2.0.0"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/${DASHBOARD_VERSION}/aio/deploy/recommended.yaml

kubectl proxy --port=8080 --address=0.0.0.0 --disable-filter=true &

#9. cloud9 실행 -> Tools / Preview / Preview Running Application 이동
# /api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
# url 뒤에 붙이고 실행

#10. jq 설치
sudo yum install jq

#11. token 생성
aws eks get-token --cluster-name eks-sample | jq -r '.status.token'

#12. cloudfront dashboard에 생성된 token 입력하여 대쉬보드 접속

#13. dashboard kill
pkill -f 'kubectl proxy --port=8080'

#14. delete dashboard
kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/${DASHBOARD_VERSION}/aio/deploy/recommended.yaml
unset DASHBOARD_VERSION
```

---

## Reference

VPC
<https://aws-diary.tistory.com/9?category=753069>

EKS 구축
<https://aws-diary.tistory.com/45?category=753089>

ALB ISTIO
<https://dev.to/airoasis/eks-eseo-istio-wa-application-load-balancer-yeongyeol-2k2j>

IAM OIDC 공급자
<https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/enable-iam-roles-for-service-accounts.html>

SNAP 설치
<https://github.com/albuild/snap>

HELM 설치
<https://helm.sh/docs/intro/install/>

ISTIO
<https://cwal.tistory.com/41>

SSL Key
<https://awskrug.github.io/eks-workshop/prerequisites/sshkey/>

AWSCLI
<https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html>

KUBECTL
<https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html>

EKSCTL
<https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html>

EKS / Istio / ALB - Settings
<https://dev.to/airoasis/aws-eks-with-eksctl-1clp>

EKS보안
<https://aws.amazon.com/ko/blogs/containers/de-mystifying-cluster-networking-for-amazon-eks-worker-nodes/>
<https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html>

EKS / ISTIO / ALB Test 배포
<https://sweetysnail1011.tistory.com/84>
<https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/alb-ingress.html>
