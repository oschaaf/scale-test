#!/bin/bash

set -e
set -u
set +x

CONTROL_PLANE=${CONTROL_PLANE:-"istio-system"}
NUM_GW=${NUM_GW:-1}
nh_pods=()
endpoints=()
pids=()
dir="out/$CONTROL_PLANE/${NUM_GW}gw"

echo "Output directory: $dir"
rm $dir/* || true 
mkdir -p $dir

IFS=' ' read -ra nh_pods <<< $(oc get pods -n nighthawk --output=jsonpath={.items..metadata.name}  --field-selector=status.phase=Running)
host="unknown"

function run_nh() {
  pod=$1
  variant=$2
  app=$3
  endpoint=$4
  $(oc -n nighthawk exec ${pod} -- nighthawk_client --concurrency 2 --connections 200 \
    --max-pending-requests 1000 --max-active-requests 200 --prefetch-connections \
    --request-header "Host: app-$app.$host.apps.ocp.scalelab" \
    --request-header "x-variant: $variant" https://${endpoint}:8443/name --rps 12000 \
    --tls-context '{common_tls_context:{tls_params:{cipher_suites:["-ALL:ECDHE-RSA-AES128-SHA"]}}}' \
    --duration 300 --label podname-$pod --label endpoint-$endpoint --label host-$host --label variant-$variant --label app-$app --output-format json 2>/dev/null 1>"$dir/nighthawk-$variant-$endpoint-$app.json" ) & 
  pid=$!
  echo "endpoint ${endpoint} / load gen ${pod} / process $pid -> $dir/nighthawk-$variant-$endpoint-$app.json"
  pids+=($pid)
}

function wait_all() {
  echo "wait for all load generators to exit .."
  for pid in "${pids[@]}"
  do
      wait $pid || true
  done
  echo "done"
}

function do_for_all_load_gens() {
  let numloadgens=${#nh_pods[@]}
  let numendpoints=${#endpoints[@]}
  let numapps=12
  let split_size=$numapps/$numloadgens
  echo $split_size
  let xcount=1
  let instance_count=1
  echo "load gen pods: ${nh_pods[@]}"
  echo "number of endpoints: ${numendpoints}"
  for podname in "${nh_pods[@]}"
  do
    ((lbound=($xcount-1)*$split_size+1))
    ((ubound=$xcount*$split_size))
    echo "$podname -> send load to apps $lbound .. $ubound"
    for i in `seq $lbound $ubound`; do
      ((endpoint_idx=$instance_count%$numendpoints))
      let instance_count=$instance_count+1
      endpoint=${endpoints[$endpoint_idx]}
      echo "$podname $endpoint_idx $endpoint"
      run_nh $podname "stable" "$i" $endpoint
      run_nh $podname "canary" "$i" $endpoint
    done
    let xcount=$xcount+1
  done
}

if [ $CONTROL_PLANE == "istio-system" ]; then
  echo "Testing istio, scaling down service mesh control plane gateways"
  host="istio"
  oc scale -n mesh-control-plane deployment istio-ingressgateway --replicas=0 --timeout=300s || true
else
  echo "Testing Service Mesh, scaling down istio-system gateways"
  host="mesh"
  oc scale -n istio-system deployment istio-ingressgateway --replicas=0 --timeout=300s || true
fi

# scale pods.
# oc scale dc -n istio-scale --all --replicas=0
# 

oc scale -n  $CONTROL_PLANE deployment istio-ingressgateway --replicas=$NUM_GW --timeout=300s
oc wait --for=condition=Ready -n $CONTROL_PLANE --all pod --timeout=300s

IFS=' ' read -ra endpoints <<< $(oc get pods -n $CONTROL_PLANE -l istio=ingressgateway -o jsonpath='{.items[*].status.podIP}')
while [[ ${#endpoints[@]} != $NUM_GW ]]; do
  echo "Waiting for the number of ready endpoints (${#endpoints[@]}) to match $NUM_GW";
  sleep 1
  IFS=' ' read -ra endpoints <<< $(oc get pods -n $CONTROL_PLANE -l istio=ingressgateway -o jsonpath='{.items[*].status.podIP}')
done

do_for_all_load_gens
wait_all
