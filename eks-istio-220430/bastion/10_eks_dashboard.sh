#1. Aws Cloud9 create environment
#2. Name / Description 작성
#3. Create and run in remote server (SSH connection) 선택
#4. user: ec2-user / host: 3.38.87.41 / port: 22
#5. copy key to clipboard

#6. sh
# key 등록
# 마지막 줄에 5번에서 복사한 key 붙여넣기
vim ~/.ssh/authorized_keys

# nvm 설치
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
. ~/.nvm/nvm.sh
nvm install node

#7. cloud9 next step

#8. k8s dashboard 설치 / 실행
export DASHBOARD_VERSION="v2.0.0"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml

kubectl proxy --port=8080 --address=0.0.0.0 --disable-filter=true &

#9. cloud9 실행 -> Tools / Preview / Preview Running Application 이동
# /api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
# url 뒤에 붙이고 실행

#10. jq 설치
sudo yum install jq

#11. token 생성
aws eks get-token --cluster-name eks-idol-live-dev | jq -r '.status.token'

#12. cloudfront dashboard에 생성된 token 입력하여 대쉬보드 접속

#13. dashboard kill
pkill -f 'kubectl proxy --port=8080'

#14. delete dashboard
kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml
unset DASHBOARD_VERSION
