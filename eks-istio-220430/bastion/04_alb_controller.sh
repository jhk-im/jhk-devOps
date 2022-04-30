aws iam list-policies

eksctl create iamserviceaccount \
  --cluster=eks-sample \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::000000000000:policy/AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --approve

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=eks-sample \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set image.repository=00000000000.dkr.ecr.ap-northeast-2.amazonaws.com/amazon/aws-load-balancer-controller

kubectl get deployment -n kube-system aws-load-balancer-controller
