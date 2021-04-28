#!/bin/bash

oc delete istiooperators.install.istio.io -n istio-system basic-install
docker run --rm --network=host -v ~/.kube:/tmp/kube istio/istioctl:1.6.13 -c /tmp/kube/config operator remove
oc delete namespace istio-scale
oc delete namespace istio-system