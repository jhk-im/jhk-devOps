cat > sample-vs.yaml << EOF
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
        prefix: /web/
    route:
    - destination:
        host: sample-front
        port:
          number: 80
EOF
kubectl apply -f sample-vs.yaml

cat > sample-gateway.yaml << EOF
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
EOF

kubectl apply -f sample-gateway.yaml
