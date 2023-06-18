#clean_saved.jl
#Script to remove saved files 

if [ `ls -1 ../data/*.save  2>/dev/null | wc -l ` -gt 0 ];
    then
    echo "Removing saved backup files"
    rm /data/*.save 
    else
    echo "no saved backup files"
    fi