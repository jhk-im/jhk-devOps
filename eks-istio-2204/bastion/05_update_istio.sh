# return istio port
kubectl get service istio-ingressgateway -n istio-system -o jsonpath='{.spec.ports[?(@.name=="status-port")].nodePort}'

cat > istio-operator-update.yaml << EOF
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
  name: istiocontrolplane
spec:
  profile: default
  components:
    egressGateways:
    - name: istio-egressgateway
      enabled: true
      k8s:
        hpaSpec:
          minReplicas: 2
    ingressGateways:
    - name: istio-ingressgateway
      enabled: true
      k8s:
        hpaSpec:
          minReplicas: 2
        service:
          type: NodePort # ingress gateway 의 NodePort 사용
        serviceAnnotations:  # Health check 관련 정보
          alb.ingress.kubernetes.io/healthcheck-path: /healthz/ready
          alb.ingress.kubernetes.io/healthcheck-port: "" # 위에서 얻은 port number를 사용
    pilot:
      enabled: true
      k8s:
        hpaSpec:
          minReplicas: 2
  meshConfig:
    enableTracing: true
    defaultConfig:
      holdApplicationUntilProxyStarts: true
    accessLogFile: /dev/stdout
    outboundTrafficPolicy:
      mode: REGISTRY_ONLY
EOF

# port 수정
vim istio-operator-update.yaml

istioctl install -f istio-operator-update.yaml
