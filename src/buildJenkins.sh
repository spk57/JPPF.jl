#!/bin/bash
# http://localhost:8080/
#This works
#sudo docker run -d -v jenkins_home:/var/jenkins_home -p 8080:8080 -p 50000:50000 --restart=on-failure jenkins/jenkins:lts-jdk11
export JULIA_HOME=/usr/local/etc/julia
export DATA=$HOME/dev/projects/jppfdata
export SRC=$HOME/dev/projects/JPPF.jl
export DEPOT=$HOME/.julia
#sudo stop [id]
sudo docker pull jenkins/jenkins
sudo docker run -d -v jenkins_home:/var/jenkins_home \
  --mount type=bind,source=$SRC,target=/src \
  --mount type=bind,source=$JULIA_HOME,target=/julia \
  --mount type=bind,source=$DATA,target=/data \
  --mount type=bind,source=$DEPOT,target=/depot \
  -p 8080:8080 -p 50000:50000 --restart=on-failure jenkins/jenkins
