aws eks --region ap-northeast-2 update-kubeconfig --name eks-sample-cluster

cat > deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-sample-deployment
  labels:
    app: app-sample
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app-sample
  template:
    metadata:
      labels:
        app: app-sample
    spec:
      containers:
        - name: app-sample
          image: kustomization-eks-repository
          imagePullPolicy: Always
          ports:
            - containerPort: 80
EOF

cat > service.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: app-sample-service
  labels:
    app: app-sample
spec:
  selector:
    app: app-sample
  ports:
    - port: 80
      targetPort: 80
      protocol: TCP
  type: NodePort
EOF

cat > istio-ingress.yaml << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-sample-ingress
  namespace: istio-system
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  rules:
    - http:
        paths:
          - pathType: Prefix
            path: /
            backend:
              service:
                name: app-sample-service
                port:
                  number: 80
EOF
kubectl apply -f kube-ingress.yaml

cat > kustomization.yaml << EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
  - istio-ingress.yaml
images:
  - name: kustomization-eks-repository
    newName: 000000000000.dkr.ecr.ap-northeast-2.amazonaws.com/image
    newTag: image_latest
EOF

# Kustomize
kustomize edit set image kustomization-eks-repository={AWS_ACCOUNT_ID}.dkr.ecr.ap-northeast-2.amazonaws.com/ecr-image:tag
kustomize build . | kubectl apply -k ./
kubectl delete -k ./

# Service
kubectl get svc
kubectl expose deployment {DEPLOYMENT_NAME} --type=LoadBalancer --name={SERVICE_NAME}
kubectl delete services {SERVICE_NAME}

# Log
kubectl logs -p {POD_NAME}