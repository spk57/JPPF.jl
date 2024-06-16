#!/bin/bash
#Run UpdateValues.sh to retrieve all history 
#Update with preferred values
#Arg 1 = number of business days of data to return
#Arg 2 = JPPF_HOME
#Arg 3 = JPPF_DATA
echo "Started update_values.sh" 
export JPPF_HOME=$2 ;                          echo "Home:   " $JPPF_HOME
export JPPF_SRC=$JPPF_HOME/src;                echo "Source: " $JPPF_SRC
export JPPF_DATA=$3 ;                          echo "Data:   " $JPPF_DATA
export JPFF_INPUT=$JPPF_DATA/track.json ;      echo "Input:  " $JPFF_INPUT
cat $JPFF_INPUT
date
cd $JPPF_HOME
echo "cd src: " ;pwd
export PATH=$PATH:/julia/bin
echo "Path: " $PATH
export JULIA_DEPOT_PATH="/depot"
echo "JULIA_DEPOT: " $JULIA_DEPOT_PATH
export JULIA_PROJECT="/src"
echo "JULIA_PROJECT: " $JULIA_PROJECT
julia -e 'using Pkg;Pkg.status()'
julia --project $JPPF_SRC/UpdateValues.jl $JPFF_INPUT $JPPF_DATA $1