git add .
git commit -m "fix: update v0.0.1"
git push origin dev 

kustomize edit set image kustomization-eks-repository={imageurl:tag}

# EKS 배포
kustomize build . | kubectl apply -k ./

# get pod
kubectl get pods -n istio

# Log
kubectl logs -p {POD_NAME}

# pod 접속
kubectl -n istio exec --stdin --tty exec -it {POD_NAME} /bin/bash