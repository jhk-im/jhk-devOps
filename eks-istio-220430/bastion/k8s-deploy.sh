#!/usr/bin/bash

if [ "" = "" ]; then
    echo "Please input istio-namespace"
   exit -1
fi

if [ "" = "" ]; then
    echo "Please input application-yaml-file"
   exit -1
fi

echo "kubectl -n  apply -f "

kubectl -n  apply -f 
kubectl -n  rollout status deployment/
