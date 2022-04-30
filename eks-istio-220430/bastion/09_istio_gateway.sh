cat > istio-vs-test.yaml << EOF
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
        host: service-2048
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

kubectl apply -f istio-vs-test.yaml
