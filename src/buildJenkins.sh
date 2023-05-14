#!/bin/bash
# http://localhost:49001/
mkdir $HOME/jenkins_home
chown 1000 $HOME/jenkins_home
#docker run -d -p 49001:8080 -v $HOME:/var/jenkins_home/jenkins --name jenkins jenkins/jenkins:jdk11
#This works
#sudo docker run -d -v jenkins_home:/var/jenkins_home -p 8080:8080 -p 50000:50000 --restart=on-failure jenkins/jenkins:lts-jdk11
sudo docker run -d -v jenkins_home:/var/jenkins_home \
  --mount type=bind,source=/home/steve/dev/projects/JPPF.jl,target=/src \
  -p 8080:8080 -p 50000:50000 --restart=on-failure jenkins/jenkins:lts-jdk11
