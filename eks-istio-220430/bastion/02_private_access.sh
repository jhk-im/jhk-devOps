# cluster 생성 확인
kubectl get nodes -o wide

# optional - private access 설정
eksctl utils update-cluster-endpoints --cluster=eks-sample --private-access=true --public-access=true --approve
eksctl utils set-public-access-cidrs --cluster=eks-sample 3.38.87.41/32 --approve
