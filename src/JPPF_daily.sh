#!/bin/bash
# Script to run from cron for daily updates to market information 

date
echo "Started JPPF_daily.sh" 
export PATH=$PATH:/julia/bin
echo "Path: " $PATH
#export JULIA_DEPOT_PATH="/depot"
#echo "JULIA_DEPOT: " $JULIA_DEPOT_PATH
#export JULIA_PROJECT="/src"
#echo "JULIA_PROJECT: " $JULIA_PROJECT
export JPPF_DATA="/home/steve/dev/projects/jppfdata"
echo "JPPF_DATA: " $JPPF_DATA
export JPPF_TICK=$JPPF_DATA/track.json
echo "JPPF_TICK: " $JPPF_TICK
julia -e 'using Pkg;Pkg.status()'
julia --project src/UpdateValues.jl -c $JPPF_TICK -o $JPPF_DATA  

