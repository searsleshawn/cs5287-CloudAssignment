# -----------------------------
# Simple Swarm autoscaler script
# -----------------------------
\
#!/usr/bin/env bash
# lag_autoscaler.sh - naive Swarm autoscaler based on Kafka consumer lag
# Requirements: curl, awk, docker CLI access on a Swarm manager
#
# Usage:
#   export EXPORTER_URL=http://localhost:9308/metrics
#   export SERVICE=your_stack_processor
#   export MIN=1
#   export MAX=5
#   export SCALE_UP_LAG=500
#   export SCALE_DOWN_LAG=50
#   ./lag_autoscaler.sh
#
set -euo pipefail

EXPORTER_URL="${EXPORTER_URL:-http://localhost:9308/metrics}"
SERVICE="${SERVICE:-iot_stack_processor}"
MIN="${MIN:-1}"
MAX="${MAX:-5}"
SCALE_UP_LAG="${SCALE_UP_LAG:-500}"
SCALE_DOWN_LAG="${SCALE_DOWN_LAG:-50}"

# Read current lag (sum over all partitions/groups named "processor")
LAG=$(curl -s "$EXPORTER_URL" | awk -F' ' '/^kafka_consumergroup_lag{.*group="processor"/ {sum+=$2} END {print sum+0}')

if [[ -z "$LAG" ]]; then
  echo "Could not read lag metric"; exit 1
fi

CURRENT=$(docker service ls --format '{{.Name}} {{.Replicas}}' | awk -v s="$SERVICE" '$1==s {print $2}' | cut -d'/' -f1)
CURRENT="${CURRENT:-$MIN}"

echo "LAG=$LAG CURRENT=$CURRENT SERVICE=$SERVICE"

if (( LAG > SCALE_UP_LAG && CURRENT < MAX )); then
  NEW=$((CURRENT+1))
  echo "Scaling up to $NEW"
  docker service scale "$SERVICE=$NEW"
elif (( LAG < SCALE_DOWN_LAG && CURRENT > MIN )); then
  NEW=$((CURRENT-1))
  echo "Scaling down to $NEW"
  docker service scale "$SERVICE=$NEW"
else
  echo "No scaling action"
fi
