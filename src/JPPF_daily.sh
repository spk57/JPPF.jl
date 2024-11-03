#!/bin/bash
# Script to run from cron for daily updates to market information 

date
echo "Started JPPF_daily.sh" 
export PATH=$PATH:/julia/bin
echo "Path: " $PATH
export JPPF_CONFIG=$(realpath ~/data/jppfconfig)
echo "JPPF_CONFIG: $JPPF_CONFIG" 
export JPPF_DATA=$(realpath ~/data/jppfdata)
echo "JPPF_DATA: " $JPPF_DATA
export JPPF_TICK=$JPPF_CONFIG/track.json
echo "JPPF_TICK: " $JPPF_TICK
#julia -e 'using Pkg;Pkg.status()'
julia --project src/UpdateValues.jl -c $JPPF_TICK -o $JPPF_DATA  

