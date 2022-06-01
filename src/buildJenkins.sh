#!/bin/bash
# http://localhost:49001/
mkdir $HOME/jenkins_home
chown 1000 $HOME/jenkins_home
docker run -d -p 49001:8080 -v $HOME:/var/jenkins_home/jenkins --name jenkins jenkins/jenkins:jdk11
