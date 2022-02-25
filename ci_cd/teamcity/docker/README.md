# teamcity-docker

## Docker settings

```zsh
docker pull --platform linux/amd64 jetbrains/teamcity-server

# /data/teamcity_server/datadir : 프로젝트 설정과 빌드 결과를 저장하는 호스트 머신 디렉토리
# /opt/teamcity/logs : 서버 로그를 저장하는 호스트 시스템 디렉토리
docker run --platform linux/amd64 -it --name teamcity-server-instance -v /data/teamcity_server/datadir -v opt/teamcity/logs -p 8111 jetbrains/teamcity-server
```

### References

<https://blog.naver.com/jetbrains_korea/221494861621>
