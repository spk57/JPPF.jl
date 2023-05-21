#!/bin/bash
#Run UpdateValues.sh
#Update with preferred values
#Arg 1 = number of business days of data to return
export JPPF_HOME=$(pwd) ;                      echo "Home:   " $JPPF_HOME
export JPPF_SRC=$JPPF_HOME/src;                echo "Source: " $JPPF_SRC
export JPPF_DATA=$HOME/dev/projects/jppfdata ; echo "Data:   " $JPPF_DATA
export JPFF_INPUT=$JPPF_DATA/track.json ;      echo "Input:  " $JPFF_INPUT
cat $JPFF_INPUT
julia --project $JPPF_SRC/UpdateValues.jl $JPFF_INPUT $JPPF_DATA $1