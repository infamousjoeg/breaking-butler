docker kill cicd_gitlab
docker kill cicd_gitlab_runner
docker kill cicd_client
docker kill cicd_conjur
docker kill cicd_database
docker kill cicd_jenkins
docker kill cicd_artifactory
docker kill cicd_sonar
docker kill cicd_scope
docker kill cicd_registry

docker rm cicd_gitlab
docker rm cicd_gitlab_runner
docker rm cicd_client
docker rm cicd_conjur
docker rm cicd_database
docker rm cicd_jenkins
docker rm cicd_artifactory
docker rm cicd_sonar
docker rm cicd_scope
docker rm cicd_registry

docker stop awx_task
docker stop awx_web
docker stop memcached
docker stop rabbitmq
docker stop postgres

docker rm awx_task
docker rm awx_web
docker rm memcached
docker rm rabbitmq
docker rm postgres


docker stop cicd_InsecureDemo
docker rm cicd_InsecureDemo
docker stop cicd_SecureDemo
docker rm cicd_SecureDemo
docker stop cicd_InsecureDemo_test
docker rm cicd_InsecureDemo_test

docker rmi cicd/insecuredemo
docker rmi cicd/securedemo


rm -rf /tmp/pgdocker/
