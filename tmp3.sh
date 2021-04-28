
set -x 

#st: https://app-2.istio.apps.ocp.scalelab
#  allowHttp2: false
#  GW addresses:
#  - 10.129.5.179:8443
#  - 10.129.7.82:8443
#  - 10.131.2.120:8443
#  - 10.129.2.74:8443

# oc rsync --watch -n nighthawk ~/nhpod example-1-m4zwh:/tmp

function run_nh() {
#    nighthawk_client --concurrency 2 --request-header "Host: $1.istio.apps.ocp.scalelab" \
#        "https://$2/proxy?p=1&url=http://$1:8080/mersennePrime?p=300" --no-duration --rps 7000 \
#        --max-pending-requests 1000 --max-active-requests 200000 --connections 125 --failure-predicate "a:1" \
#        --request-header "x-variant: stable" 2>&1 > "$1.txt" &
    nighthawk_client --concurrency 2 --duration 60 --request-header "Host: $1.istio.apps.ocp.scalelab" \
        "https://$2/mersennePrime?p=1" --rps 7000 \
        --max-pending-requests 2500  --max-active-requests 200000 --connections 200 --failure-predicate "a:1" \
        --request-header "x-variant: stable" 2>&1 > "$1-stable.txt" &
    nighthawk_client --concurrency 1 --duration 60 --request-header "Host: $1.istio.apps.ocp.scalelab" \
        "https://$2/mersennePrime?p=1" --rps 7000 \
        --max-pending-requests 2500 --max-active-requests 200000 --connections 100 --failure-predicate "a:1" \
        --request-header "x-variant: canary" 2>&1 > "$1-canary.txt" &
}

# "msg": "10.129.4.37 10.131.2.82 10.129.6.4 10.129.2.168"

for i in `seq 1 12`; do 
    #nighthawk_client --concurrency 1 --request-header "Host: app-$i.istio.apps.ocp.scalelab" \
    #    "https://10.129.6.4:8443/mersennePrime?p=1" --no-duration --rps 8000 \
    #    --max-pending-requests 2500 --max-active-requests 200000 --connections 800 --failure-predicate "a:1" \
    #    --request-header "x-variant: stable" 2>&1 > "app-$i-stable.txt" &
    #nighthawk_client --concurrency 1 --request-header "Host: app-$i.istio.apps.ocp.scalelab" \
    #    "https://10.129.6.4:8443/mersennePrime?p=1" --no-duration --rps 2000 \
    #    --max-pending-requests 2500 --max-active-requests 200000 --connections 200 --failure-predicate "a:1" \
    #    --request-header "x-variant: canary" 2>&1 > "app-$i-canary.txt" &
    #nighthawk_client --concurrency 1 --request-header "Host: app-$i.istio.apps.ocp.scalelab" \
    #    "https://10.129.2.168:8443/mersennePrime?p=1" --no-duration --rps 4000 \
    #    --max-pending-requests 2500 --max-active-requests 200000 --connections 400 --failure-predicate "a:1" \
    #    --request-header "x-variant: stable" 2>&1 > "app-$i-stable.txt" &
    #nighthawk_client --concurrency 1 --request-header "Host: app-$i.istio.apps.ocp.scalelab" \
    #    "https://10.129.2.168:8443/mersennePrime?p=1" --no-duration --rps 1000 \
    #    --max-pending-requests 2500 --max-active-requests 200000 --connections 100 --failure-predicate "a:1" \
    #    --request-header "x-variant: canary" 2>&1 > "app-$i-canary.txt" &
    echo "foo"
done

#exit 0


for i in `seq 13 18`; do 
    run_nh "app-$i" "10.129.4.37:8443"; 
done

#for i in `seq 19 24`; do 
#    run_nh "app-$i" "10.131.2.87:8443"; 
#done


#for i in `seq 4 7`; do 
#    run_nh "app-$i" "10.129.4.37:8443"; 
#done

#for i in `seq 11 15`; do 
#    run_nh "app-$i" "10.129.2.168:8443"; 
#done

#for i in `seq 21 30`; do 
#    run_nh "app-$i" "10.131.2.120:8443"; 
#done


echo "done"

