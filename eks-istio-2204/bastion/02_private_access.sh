# cluster 생성 확인
kubectl get nodes -o wide

# optional - private access 설정
eksctl utils update-cluster-endpoints --cluster=eks-sample --private-access=true --public-access=true --approve
eksctl utils set-public-access-cidrs --cluster=eks-sample {bastion server pulic ip} --approve

aws eks --region ap-northeast-2 update-kubeconfig --name eks-sample-cluster