cat > pod_admin.yaml << EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: istio-sample
  name: deployment-admin
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: app-admin
  replicas: 1
  template:
    metadata:
      labels:
        app.kubernetes.io/name: app-admin
    spec:
      containers:
      - image: 000000000000.dkr.ecr.ap-northeast-2.amazonaws.com/sample:v0.0.1
        imagePullPolicy: Always
        name: app-admin
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  namespace: istio-sample
  name: service-admin
spec:
  ports:
    - port: 80
      targetPort: 80
      protocol: TCP
  type: NodePort
  selector:
    app.kubernetes.io/name: app-admin
EOF

kubectl apply -f pod_admin.yaml

cat > istio-gw-admin.yaml << EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  namespace: istio-sample
  name: sample-virtualservice
spec:
  hosts:
  - "*"
  gateways:
  - sample-gateway

  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: service-admin
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

kubectl apply -f istio-gw-admin.yaml
