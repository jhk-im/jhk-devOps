# AWS EKS Sample

## Amazon EKS 시작하기

```zsh
# kubectl 설치
curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/darwin/amd64/kubectl
kubectl version

# eksctl 설치
brew tap weaveworks/tap
brew install weaveworks/tap/eksctl
brew install weaveworks/tap/eksctl
eksctl version

# awscli 설치
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg ./AWSCLIV2.pkg -target /
which aws
aws --version
```

## AWS Console / AWS CLI

스택 생성
<https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/creating-a-vpc.html>

```zsh
# cloudformation stack 생성
aws cloudformation create-stack \
  --region ap-northeast-2 \
  --stack-name my-eks-vpc-stack \
  --template-url https://amazon-eks.s3.us-west-2.amazonaws.com/cloudformation/2020-08-12/amazon-eks-vpc-sample.yaml
```

```json
// 출력
{
    "StackId": "******"
}

// cluster-role-trust-policy.json
{
    "Role": {
        "Path": "/",
        "RoleName": "myAmazonEKSClusterRole",
        "RoleId": "******",
        "Arn": "arn:aws:iam::******:role/myAmazonEKSClusterRole",
        "CreateDate": "2022-03-10T15:06:44+00:00",
        "AssumeRolePolicyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {
                        "Service": "eks.amazonaws.com"
                    },
                    "Action": "sts:AssumeRole"
                }
            ]
        }
    }
}

```zsh
// role
aws iam create-role --role-name myAmazonEKSClusterRole --assume-role-policy-document file://"cluster-role-trust-policy.json"

// iam
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy --role-name myAmazonEKSClusterRole  
```

eks cluster 생성
<https://docs.aws.amazon.com/ko_kr/eks/latest/userguide/getting-started-console.html>

```zsh
rm ~/.kube/config

aws eks update-kubeconfig --region region-code --name my-cluster

kubectl get svc
```
