#!/bin/bash
# Script to run from cron for daily updates to market information 

date
echo "Started JPPF_daily.sh" 
cd src
echo "cd src: " pwd
export PATH=$PATH:/julia/bin
echo "Path: " $PATH
export JULIA_DEPOT_PATH="/depot"
echo "JULIA_DEPOT: " $JULIA_DEPOT_PATH
export JULIA_PROJECT="/src"
echo "JULIA_PROJECT: " $JULIA_PROJECT
julia -e 'using Pkg;Pkg.status()'
