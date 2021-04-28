#!/bin/bash

function process() {
    n=$(basename $1 .json)
    d=$(dirname $1)
    echo "Processing $1"
    cat $1 | docker run -i envoyproxy/nighthawk-dev:latest nighthawk_output_transform --output-format human > "$d/$n.txt"
}
for f in out/istio-system/1gw/*.json; do process $f; done
for f in out/istio-system/2gw/*.json; do process $f; done
for f in out/istio-system/3gw/*.json; do process $f; done
for f in out/istio-system/4gw/*.json; do process $f; done

for f in out/mesh-control-plane/1gw/*.json; do process $f; done
for f in out/mesh-control-plane/2gw/*.json; do process $f; done
for f in out/mesh-control-plane/3gw/*.json; do process $f; done
for f in out/mesh-control-plane/4gw/*.json; do process $f; done
