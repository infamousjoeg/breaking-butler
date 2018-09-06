#!/bin/bash -e

####################
# Configuration
####################


export SERVER_IP='localhost'
export GITLAB_ROOT_PASSWORD=$(openssl rand -hex 12)
export JENKINS_ADMIN_PASSWORD=$(openssl rand -hex 12)
export AWX_PASSWORD=$(openssl rand -hex 12)
export JENKINS_ADMIN_USER=admin
export CONJUR_ACCOUNT=demo
export ADMIN_EMAIL='mike@cyberarkdemo.com'


rm -rf ./workspace
mkdir ./workspace

echo "#################################"
echo "# ansible"
echo "#################################"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


[[ -n `which ansible-playbook` ]] || $DIR/install_ansible.sh

ansible-galaxy install cyberark.conjur
ansible-galaxy install drhelius.docker


echo "Ansible is ready!."

echo "#################################"
echo "# Docker Platform"
echo "#################################"

ansible-playbook ./playbook/setup_docker.yml

echo "#################################"
echo "# Create Docker Private Registry"
echo "#################################"

docker run --name cicd_registry -d --restart always -p 5000:5000 -v /opt/docker/registry:/var/lib/registry registry:2
sleep 5
docker login -u admin -p admin localhost:5000
sleep 5

echo "#################################"
echo "# Pull Images"
echo "#################################"

docker-compose pull
docker pull localhost:5000/openjdk:8-jre-alpine

echo "#################################"
echo "# Generate Conjur Data Key"
echo "#################################"

docker-compose run --no-deps --rm conjur data-key generate > data_key
export CONJUR_DATA_KEY="$(< data_key)"


echo "#################################"
echo "# Deploy Containers"
echo "#################################"

SERVER_IP=${SERVER_IP} \
GITLAB_ROOT_PASSWORD=${GITLAB_ROOT_PASSWORD} \
GITLAB_ROOT_EMAIL="mike@cyberarkdemo.com" \
docker-compose up -d


echo "#################################"
echo "# Setup Conjur Account"
echo "#################################"

sleep 5
conjur_admin_api=$(docker-compose exec conjur conjurctl account create ${CONJUR_ACCOUNT})
conjur_pass=$(echo ${conjur_admin_api}|sed 's/.* //')

echo "#################################"
echo "# Setup Jenkins"
echo "#################################"


if [ ! -d downloads ]; then
    mkdir downloads

    curl  -j -k -L -H "Cookie: oraclelicense=accept-securebackup-cookie" -o ./downloads/jdk-9.0.4_linux-x64_bin.tar.gz http://download.oracle.com/otn-pub/java/jdk/9.0.4+11/c2514751926b4512b076cc82f959763f/jdk-9.0.4_linux-x64_bin.tar.gz
    curl  -j -k -L -H "Cookie: oraclelicense=accept-securebackup-cookie" -o ./downloads/jdk-8u162-linux-x64.tar.gz http://download.oracle.com/otn-pub/java/jdk/8u162-b12/0da788060d494f5095bf8624735fa2f1/jdk-8u162-linux-x64.tar.gz

    curl -o ./downloads/apache-maven-3.5.3-bin.tar.gz http://apache.communilink.net/maven/maven-3/3.5.3/binaries/apache-maven-3.5.3-bin.tar.gz

    curl -L -o downloads/jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 && chmod +x downloads/jq

fi

docker cp ./downloads/jdk-9.0.4_linux-x64_bin.tar.gz  cicd_jenkins:/tmp/jdk-9.0.4_linux-x64_bin.tar.gz
docker cp ./downloads/jdk-8u162-linux-x64.tar.gz cicd_jenkins:/tmp/jdk-8u162-linux-x64.tar.gz
docker cp ./downloads/apache-maven-3.5.3-bin.tar.gz cicd_jenkins:/tmp/apache-maven-3.5.3-bin.tar.gz

docker cp ./jenkins/plugins.txt cicd_jenkins:/tmp/plugins.txt
docker exec cicd_jenkins sh -c 'xargs /usr/local/bin/install-plugins.sh < /tmp/plugins.txt' || true

theScript=`cat ./jenkins/java.groovy`
curl -d "script=${theScript}" http://${SERVER_IP}:32080/scriptText

theScript=`cat ./jenkins/maven.groovy`
curl -d "script=${theScript}" http://${SERVER_IP}:32080/scriptText

theScript=`cat ./jenkins/security.groovy`
curl -d "script=${theScript//xPASSx/$JENKINS_ADMIN_PASSWORD}" http://${SERVER_IP}:32080/scriptText

echo "Sleeping for 10 seconds... be right back. :-)"
sleep 10

docker restart cicd_jenkins

echo "#################################"
echo "# Download Summon"
echo "#################################"

curl -L -o downloads/summon.tar.gz https://github.com/cyberark/summon/releases/download/v0.6.6/summon-linux-amd64.tar.gz
curl -L -o downloads/summon-conjur.tar.gz https://github.com/cyberark/summon-conjur/releases/download/v0.5.0/summon-conjur-linux-amd64.tar.gz

cd downloads/
tar zvxf summon.tar.gz
tar zvxf summon-conjur.tar.gz
cd ..

echo "#################################"
echo "# Setup AWX"
echo "#################################"

cd downloads

pip uninstall -y docker-py
pip uninstall -y docker
pip install docker

if [ ! -d awx ]; then
  git clone https://github.com/ansible/awx.git
fi

cd ./awx/installer
sed -i "s,host_port=80,host_port=34080,g" ./inventory
sed -i "s,.*default_admin_password=.*,default_admin_password=${AWX_PASSWORD},g" ./inventory
sed -i "s,# default_admin_user=admin,default_admin_user=admin,g" ./inventory
ansible-playbook -i inventory install.yml
cd ../../..


docker network connect cicd_default rabbitmq
docker network connect cicd_default postgres
docker network connect cicd_default memcached
docker network connect cicd_default awx_web
docker network connect cicd_default awx_task

echo "#################################"
echo "# Create Docker Service Account"
echo "#################################"
ansible-playbook playbook/create_docker_user.yml
DOCKER_SSH_KEY="/home/cicd_service_account/.ssh/id_rsa"

echo "#################################"
echo "# Setup Gitlab & CI runner"
echo "#################################"

docker exec cicd_gitlab gem install mechanize
docker cp ./gitlab/getcitoken.rb cicd_gitlab:/tmp/getcitoken.rb
docker exec cicd_gitlab chmod +x /tmp/getcitoken.rb


# Wait for GITLAB web service
while [[ "$(curl --write-out %{http_code} --silent --output /dev/null http://${SERVER_IP}:31080/users/sign_in)" != "200" ]]; do 
    printf '.'
    sleep 5
done

# Wait for GITLAB Runner Registration Token
until [[ -z "$(docker exec cicd_gitlab ruby /tmp/getcitoken.rb | grep 'Error')"   ]]; do sleep 5s ; done
CI_SERVER_TOKEN="$(docker exec cicd_gitlab ruby /tmp/getcitoken.rb)"

docker exec cicd_gitlab_runner gitlab-runner register --non-interactive \
  --url "http://${SERVER_IP}:31080/" \
  -r "${CI_SERVER_TOKEN}" \
  --executor shell


docker exec cicd_gitlab_runner gitlab-runner start


echo "#################################"
echo "# Save details to result file"
echo "#################################"

cat > ./workspace/config << EOL
SERVER_IP=${SERVER_IP} 
CONJUR_DATA_KEY=${CONJUR_DATA_KEY}
CONJUR_URL=${SERVER_IP}:8080
CONJUR_USER=admin
CONJUR_PASS=${conjur_pass}
CONJUR_ACCOUNT=${CONJUR_ACCOUNT}
GITLAB_URL=${SERVER_IP}:31080
GITLAB_USER=root
GITLAB_PASS=${GITLAB_ROOT_PASSWORD} 
GITLAB_EMAIL=${ADMIN_EMAIL} 
GITLAB_CI_SERVER_TOKEN=${CI_SERVER_TOKEN}
JENKINS_URL=${SERVER_IP}:32080
JENKINS_USER=admin
JENKINS_PASS=${JENKINS_ADMIN_PASSWORD}
ARTIFACTORY_URL=${SERVER_IP}:33081
ARTIFACTORY_USER=admin
ARTIFACTORY_PASS=password
SONAR_URL=${SERVER_IP}:34000
SONAR_USER=admin
SONAR_PASS=admin
SCOPE_URL=${SERVER_IP}:4040
AWX_URL=${SERVER_IP}:34080
AWX_USER=admin
AWX_PASS=${AWX_PASSWORD}
DOCKER_SSH_USER=cicd_service_account
DOCKER_SSH_KEY="${DOCKER_SSH_KEY}"

EOL

cat > ./workspace/conjur_config << EOL
CONJUR_API="${conjur_admin_api}"
EOL

rm -f data_key

echo "###################################"
echo "# CI/CD Pipeline systems installed"
echo "###################################"

