cat > istio-ingress.yaml << EOF
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
    # AWS Certificate Manager certificate's ARN -> 
    alb.ingress.kubernetes.io/certificate-arn: ""
    # open ports 80 and 443
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS":443}]'
    # redirect all HTTP to HTTPS
    alb.ingress.kubernetes.io/actions.ssl-redirect: '{"Type": "redirect", "RedirectConfig": { "Protocol": "HTTP", "Port": "80", "StatusCode": "HTTP_301"}}'
spec:
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: ssl-redirect
                port:
                  name: use-annotation
          - path: /
            pathType: Prefix
            backend:
              service:
                name: istio-ingressgateway
                port:
                  number: 80
EOF

kubectl apply -f istio-ingress.yaml
