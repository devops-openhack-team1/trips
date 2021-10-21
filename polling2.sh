#!/bin/bash

declare -i duration=
declare hasUrl=""
declare endpoint
declare -i status200count=0

usage(){
    cat<<END    
    healthcheck.sh [-i] [-h] endpoint
    Report the health status of the endpoint    
    -i: include Uri for the format    
    -h: help
END
}
while getopts "ih" opt; do 
case $opt in
    i)
    hasUrl=true
    ;;    
    h)
    usage
    exit 0
    ;;
    \?)
    echo "Unknown option: -${OPTARG}">&2
    exit 1
    ;;
esac
done
shift $((OPTIND -1))

if [[ $1 ]]; then
endpoint=$1
else
echo "Please specify the endpoint."
usage
exit 1
fi

healthcheck() {
    declare url=$1
    result=$(curl -i $url 2>/dev/null |grep HTTP/2)
    echo $result
}

for i in {1..12}
do
result=$(curl -i $endpoint 2>/dev/null |grep HTTP/2)
declare status
if [[ -z $result ]]; then
    status="N/A"
    echo "Site not found: $endpoint"
else
    status=${result:7:3}
    timestamp=$(date "+%Y%m%d-%H%M%S")
    if [[ -z $hasUrl ]]; then
    echo "$timestamp | $status "
    else
    echo "$timestamp | $status | $endpoint "
    fi
    if [ $status -eq 200 ]; then
    ((status200count=status200count + 1))
    
        if [ $status200count -gt 5 ]; then
            break
        fi
    fi
    sleep $duration
fi
done

if [ $status200count -gt 5 ]; then 
    echo "API UP"
    # APISTATUS is a pipeline variable
    APISTATUS="Up"
    echo "APIPRODSTATUS=true" >> ${GITHUB_ENV} 
    else
    echo "API DOWN"
    APISTATUS="Down"
    echo "APIPRODSTATUS=false" >> $GITHUB_ENV
    exit 1;
fi

