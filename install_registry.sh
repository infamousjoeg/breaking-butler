#!/bin/bash
# This script is to install a private Docker Registry for offline use
# The Docker Registry will be populated with the proper Docker Images
set -eou pipefail

# Create array of Docker Images
images=( "weaveworks/scope:latest" "sonarqube:lts" "openjdk:8-jre-alpine" "postgres:9.3" "gitlab/gitlab-ce:latest" "cyberark/conjur:latest" "gitlab/gitlab-runner:latest" "jenkins/jenkins:lts" "conjurinc/cli5:latest" "docker.bintray.io/jfrog/artifactory-oss:5.9.1" )

echo "#######################"
echo "# Run Docker Registry"
echo "#######################"

docker run --name cicd_registry -d --restart always -p 5000:5000 -v /opt/docker/registry:/var/lib/registry registry:2
docker login -u admin -p admin localhost:5000

echo "#######################"
echo "# Pulling Docker Images"
echo "#######################"

for image in "${images[@]}"
do
    docker pull $image
done

echo "#######################"
echo "# Tagging Docker Images"
echo "#######################"

for image in "${images[@]}"
do
    docker tag $image localhost:5000/$image
done

echo "#######################"
echo "# Removing Local Images"
echo "#######################"

for image in "${images[@]}"
do
    docker rmi $image
done

echo "#######################"
echo "# Pushing Docker Images"
echo "#######################"

for image in "${images[@]}"
do
    docker push localhost:5000/$image
done

docker rm -f cicd_registry

echo ""
echo "Successfully completed."