#!/bin/bash

set -e
set -u
set +x

rm -rf out/* 2>/dev/null || true

NUM_GW=1 CONTROL_PLANE=istio-system ./genload.sh
NUM_GW=2 CONTROL_PLANE=istio-system ./genload.sh
NUM_GW=3 CONTROL_PLANE=istio-system ./genload.sh
NUM_GW=4 CONTROL_PLANE=istio-system ./genload.sh

NUM_GW=1 CONTROL_PLANE=mesh-control-plane ./genload.sh
NUM_GW=2 CONTROL_PLANE=mesh-control-plane ./genload.sh
NUM_GW=3 CONTROL_PLANE=mesh-control-plane ./genload.sh
NUM_GW=4 CONTROL_PLANE=mesh-control-plane ./genload.sh

