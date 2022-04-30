# cluster 생성
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
