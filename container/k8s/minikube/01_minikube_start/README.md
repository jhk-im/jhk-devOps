# Minikube_start

***What you’ll need***

* **2 CPUs** or more
* **2GB** of free memory
* **20GB** of free disk space
* Internet connection
* Container or virtual machine manager, such as: **Docker**, Hyperkit, Hyper-V, KVM,  Parallels, Podman, VirtualBox, or VMware Fusion/Workstation

***설치환경***

* m1 macbook pro

## Minikube

### 사전 준비

* Docker 기초 -> [Docker for beginners](https://docker-curriculum.com/#getting-started)
* Kubernetes 기초 -> [초보를 위한 쿠버네티스 안내서](https://www.youtube.com/watch?v=Ia8IfowgU7s)
* Kubectl 설치 -> [Mac OS kubectl Homebrew 설치](https://kubernetes.io/ko/docs/tasks/tools/install-kubectl-macos/#install-with-homebrew-on-macos)

#### 1. Installation

```zsh
brew install minikube

# /usr/local/bin/minikube
which minikube 

# which minikube fails
brew unlink minikube
brew link minikube
```

#### 2. Start cluster

```zsh
minikube start --driver=docker
# or
# 기본 driver를 docker로 설정 / 실행 시 적용
minikube config set driver docker
minikube start 
```

*Minikube run*
![ms_01](./images/ms_01.png)

*Docker run*
![ms_02](./images/ms_02.png)

#### 3. Cluster 상호작용

```zsh
# 리소스 목록에서 모든 pod 정보 확인 
kubectl get po -A
```

![ms_03](./images/ms_03.png)

```zsh
# Dashboard 지원
minikube dashboard
```

![ms_04](./images/ms_04.png)

#### 4. Deploy applications

```zsh
# Sample Deployment 생성 / 8080 port 
kubectl create deployment catnip-minikube --image=kjhun/catnip
kubectl expose deployment catnip-minikube --type=NodePort --port=8080
```

![ms_05](./images/ms_05.png)

```zsh
# catnip-minikube Deployment 실행 확인 
kubectl get services catnip-minikube
```

![ms_06](./images/ms_06.png)

```zsh
# minikube로 웹 브라우저 실행
minikube service catnip-minikube
```

![ms_07](./images/ms_07.png)

```zsh
# kubectl을 사용하요 포트포워딩 
kubectl port-forward service/catnip-minikube 7080:8080
```

![ms_08](./images/ms_08.png)

<http://localhost:7080/>
![ms_09](./images/ms_09.png)

❓an error occurred forwarding 7080 ... 🤔

```zsh
# LoadBalancer Deployment
kubectl create deployment balanced --image=k8s.gcr.io/echoserver:1.4
kubectl expose deployment balanced --type=LoadBalancer --port=8080
```

![ms_10](./images/ms_10.png)

```zsh
# balanced deployment를 위한 routable IP 생성
minikube tennel
```

![ms_11](./images/ms_11.png)

```zsh
# EXTERNAL-IP 확인
kubectl get services balanced
```

*EXTERNAL-IP:8080 에서 Deployment 사용가능*
![ms_12](./images/ms_12.png)

#### 5. Cluster 관리

```zsh
# 배포된 애플리케이션에 영향 없이 k8s 일시중지
minikube pause

# 일시중지 해제
minikube unpause

# 클러스터 중지
minikube stop

# 기본 메모리 설정 / 다시 시작할때 적용 됨 
minikube config set memory 16384

# 쉽게 설치할 수 있는 k8s service 목록 
minikube addons list

# 예전 k8s release로 클러스터 생성 실행 
minikube start -p aged --kubernetes-version=v1.16.1

# minikube cluster 모두 삭제 
minikube delete --all
```

---

### Reference

* [Minikube start](https://minikube.sigs.k8s.io/docs/start/)
