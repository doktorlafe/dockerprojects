# 18 - Jenkins CI/CD

Jenkins server pro continuous integration.

## Spuštění

```bash
cd 18-jenkins-ci
docker-compose up
```

Jenkins: http://localhost:8080

Počáteční heslo se nachází v:
```bash
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```
