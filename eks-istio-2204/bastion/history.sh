# logs
kubectl logs -f deployment.apps/aws-load-balancer-controller -n kube-system
kubectl logs deployment.apps/aws-load-balancer-controller -n kube-system

istioctl x uninstall --filename
istioctl x uninstall

kubectl get namespace istio-system -o yaml
kubectl get all -n istio-system
kubectl get ingress -n istio-system
kubectl -n istio-system get svc istio-ingressgateway

# 강제삭제
kubectl get namespace "istio-system" -o json \
  | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" \
  | kubectl replace --raw /api/v1/namespaces/"istio-system"/finalize -f -

kubectl replace -f 4_istio-ingress.yaml

kubectl -n istio-system get svc istio-ingressgateway
kubectl -n istio-system edit svc istio-ingressgateway
kubectl -n istio-system get deploy istio-ingressgateway -o yaml

# alb.ingress.kubernetes.io/healthcheck-path: /healthz/ready
# alb.ingress.kubernetes.io/healthcheck-port: "32522"

cat > 4_istio-ingress.yaml << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: istio-ingress
  namespace: istio-system
  annotations:
    # create AWS Application LoadBalancer
    kubernetes.io/ingress.class: alb
    # external type
    alb.ingress.kubernetes.io/scheme: internet-facing
    # AWS Certificate Manager certificate's ARN -> alb.ingress.kubernetes.io/certificate-arn: ""
    # open ports 80 and 443 
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS":443}]'
    # redirect all HTTP to HTTPS
    alb.ingress.kubernetes.io/actions.ssl-redirect: '{"Type": "redirect", "RedirectConfig": { "Protocol": "HTTP", "Port": "80", "StatusCode": "HTTP_301"}}'
spec:
  rules:
    - http:
        paths:
          - path: /*
            pathType: Prefix
            backend:
              service:
                name: ssl-redirect
                port:
                  name: use-annotation
          - path: /*
            pathType: Prefix
            backend:
              service:
                name: istio-ingressgateway
                port:
                  number: 80
EOF

kubectl apply -f 4_istio-ingress.yaml
kubectl -n istio-system get ingress


# Kustomize
kustomize edit set image kustomization-eks-repository={imageurl}

kustomize build . | kubectl apply -k ./
kubectl delete -k ./

kubectl -n istio-system edit svc istio-ingressgateway

#
kubectl get sa -n kube-system
kubectl get nodes -o wide

eksctl get clusters --region=ap-northeast-2
aws eks --region ap-northeast-2 update-kubeconfig --name {cluster-name}

참고
https://rtfm.co.ua/en/istio-external-aws-application-loadbalancer-and-istio-ingress-gateway/
https://velog.io/@airoasis/EKS-%EC%97%90%EC%84%9C-Istio-%EC%99%80-ALB-%EC%97%B0%EA%B2%B0
https://itnext.io/deploying-an-istio-gateway-with-tls-in-eks-using-the-aws-load-balancer-controller-448812e081e5