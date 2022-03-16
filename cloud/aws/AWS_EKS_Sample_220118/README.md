# AWS EKS Sample

## settings

```zsh

#
# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

unzip awscliv2.zip

sudo ./aws/install 

aws --version

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

#
# IAM Policy
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.3.1/docs/install/iam_policy.json

aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

# 0000 -> account id
eksctl create iamserviceaccount \
  --cluster=eks-demo \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::0000:policy/AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --approve

# bastion 서버에서만 k8s에 명령을 내릴 수 있도록
eksctl utils update-cluster-endpoints --cluster=eks-sample --private-access=true --public-access=true --approve
# 0.0.0.0 -> bastion server ip
eksctl utils set-public-access-cidrs --cluster=eks-sample 0.0.0.0/32 --approve

#
# istioctl 설치
curl -sL https://istio.io/downloadIstioctl | sh -
cp ~/.istioctl/bin/istioctl ~/bin

# istio 설치 
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
kubectl label namespace default istio-injection=enabled

#
# ALB 연결
# ALB IAM Policy
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.3.1/docs/install/iam_policy.json

aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

# 0000 -> accout id
eksctl create iamserviceaccount \
  --cluster=eks-sample \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::0000:policy/AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --approve

# HELM
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3

chmod 700 get_helm.sh

./get_helm.sh

helm repo add eks https://aws.github.io/eks-charts

# ALB - HELM
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=eks-sample \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set image.repository=602401143452.dkr.ecr.ap-northeast-2.amazonaws.com/amazon/aws-load-balancer-controller

kubectl get deployment -n kube-system aws-load-balancer-controller

# istio 설정 변경  ex ) 30587 반환
kubectl get service istio-ingressgateway -n istio-system -o jsonpath='{.spec.ports[?(@.name=="status-port")].nodePort}'

rm -rf istio-operator.yaml

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
        service:
          type: NodePort # ingress gateway 의 NodePort 사용
        serviceAnnotations:  # Health check 관련 정보
          alb.ingress.kubernetes.io/healthcheck-path: /healthz/ready
          alb.ingress.kubernetes.io/healthcheck-port: "30587" # 위에서 얻은 port number를 사용
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

EKS / ISTIO / ALB Test 배포
<https://sweetysnail1011.tistory.com/84>
<https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/alb-ingress.html>

```zsh
# test ingress 배포
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.0/docs/examples/2048/2048_full.yaml

kubectl get ingress/ingress-2048 -n game-2048

# EKS Cluster 생성시 eksctl --dry-run 옵션으로 yaml 파일을 만들어 관련 설정을 한번에 만들 수 있음
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
