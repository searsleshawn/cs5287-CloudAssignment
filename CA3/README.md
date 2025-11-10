# CA3 – Cloud-Native Ops: Observability, Scaling & Hardening

## Overview
This project extends the CA2 IoT event-processing pipeline into a **production-grade, observable, secure, and self-healing cloud-native deployment**.  
It operates on **Docker Swarm**, integrating **Prometheus + Grafana + Loki** for observability, **TLS for all critical services**, and **automated scaling** based on Kafka consumer lag.

---

## Architecture
### Key Components
| Layer | Services | Description |
|--------|-----------|-------------|
| **IoT Pipeline** | Kafka, Zookeeper, MongoDB, Producer, Processor | Handles event ingestion, processing, and storage. |
| **Observability** | Prometheus, Grafana, Loki, Promtail, cAdvisor | Monitors performance and logs across all containers. |
| **Security** | Docker secrets + TLS certificates | Protects credentials and data in transit. |
| **Resilience** | Swarm auto-restart + chaos testing | Ensures fault recovery and reliability. |
| **Scaling** | Custom autoscaler script | Dynamically scales processor replicas based on Kafka lag. |

---

## Directory Structure
```
ansible/
├── templates/
│   ├── iot_stack.yml.j2        # IoT pipeline with TLS
│   ├── obs_stack.yml.j2        # Observability stack with TLS
│   ├── prometheus.yml.j2       # Prometheus scrape targets
│   ├── promtail-config.yml.j2  # Log collector configuration
│   ├── autoscaler.sh           # Kafka lag-based autoscaler
│   ├── chaos.yml               # Failure injection / resilience drill
│   └── site.yml                # Deployment orchestration playbook
└── README.md                   # Documentation (this file)
```

---

## Deployment Instructions

### 1. Prerequisites
- Docker Swarm initialized and all nodes joined.
- Overlay networks created:
  ```bash
  docker network create -d overlay iot_net
  docker network create -d overlay metrics_net
  ```
- Secrets already created or available via Ansible vault:
  ```bash
  docker secret ls
  ```

### 2. Certificates (TLS)
All certificates are stored on the manager node under `/opt/certs`:

```
/opt/certs/kafka/kafka.crt
/opt/certs/kafka/kafka.key
/opt/certs/mongo/mongo.crt
/opt/certs/mongo/mongo.key
/opt/certs/grafana/grafana.crt
/opt/certs/grafana/grafana.key
```

If missing, generate self-signed certs:
```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048   -keyout /opt/certs/kafka/kafka.key -out /opt/certs/kafka/kafka.crt   -subj "/CN=kafka"
```

---

### 3. Deploy Stacks
#### IoT Pipeline
```bash
docker stack deploy -c /opt/stacks/iot_stack.yml iot_stack
```

#### Observability Stack
```bash
docker stack deploy -c /opt/stacks/obs_stack.yml obs_stack
```

---

## Observability & Metrics

### Prometheus
- URL: `http://<manager>:9090`
- Scrapes metrics from:
  - Kafka Exporter (`kafka_consumergroup_lag`)
  - MongoDB Exporter (`mongodb_op_counters`)
  - Producer / Processor custom metrics
  - cAdvisor for node-level CPU/memory

### Grafana
- URL: `https://<manager>:3443`
- Credentials: stored in Docker secrets `grafana_user`, `grafana_pass`
- Default dashboards:
  - Kafka Consumer Lag
  - MongoDB Inserts/sec
  - Node Resource Usage

### Loki / Promtail
- Centralized log aggregation from all containers
- Query via Grafana using `loki` data source
- Structured JSON parsing (`time`, `level`, `msg`)

---

## Scaling Automation

### Autoscaler Script (`autoscaler.sh`)
- Reads `kafka_consumergroup_lag` metric via HTTP.
- Scales the processor service between MIN/MAX replicas.

Example usage:
```bash
export EXPORTER_URL=http://localhost:9308/metrics
export SERVICE=iot_stack_processor
export MIN=1
export MAX=5
export SCALE_UP_LAG=500
export SCALE_DOWN_LAG=50
./autoscaler.sh
```

Add a cron job to automate:
```
*/1 * * * * /opt/scripts/autoscaler.sh >> /var/log/autoscaler.log 2>&1
```

---

## Security Hardening

### Secrets Management
- All credentials (`mongo_user`, `mongo_pass`, etc.) are stored as **Swarm secrets**.
- TLS certs are mounted from `/opt/certs` as read-only secrets.

### Network Isolation
- `iot_net`: IoT application communication (Kafka, Mongo, Producers, Processors)
- `metrics_net`: observability-only network for Prometheus, Grafana, Loki, etc.

### TLS Encryption
- Kafka broker and clients use SSL on port `9093`.
- MongoDB enforces `requireTLS` for all connections.
- Grafana served via HTTPS on port `3443`.

---

## Resilience Drill

### Chaos Test (`chaos.yml`)
Simulates pod failure and verifies self-healing behavior.

Example:
```bash
docker service rm iot_stack_processor
watch docker service ls
```

Expected outcome:
- Swarm reschedules the service automatically.
- Processor service resumes normal operation.
- Logs and metrics confirm recovery.

---

## Validation

### Verify TLS
```bash
openssl s_client -connect kafka:9093 -showcerts
mongo --tls --tlsCAFile /opt/certs/mongo/mongo.crt --host mongo
curl -k https://<manager>:3443
```

### Verify Scaling
```bash
docker service ls
```
Watch processor replica count increase/decrease based on Kafka lag.

### Verify Logs
Check Loki pipeline:
```bash
docker service logs obs_stack_promtail --tail 20
```

---

## Deliverables Summary

| Category | Description | Evidence |
|-----------|-------------|-----------|
| **Observability** | Centralized logging & metrics dashboard | Grafana dashboard screenshots |
| **Autoscaling** | Kafka lag-based scaling | autoscaler logs, service scaling output |
| **Security** | TLS, secrets, network segmentation | YAML configs, cert mounts |
| **Resilience** | Failure recovery demo | Short video, chaos.yml output |
| **Documentation** | Complete setup instructions | This README |

---

## Grading Criteria Alignment

| Rubric Area | Implementation | Status |
|--------------|----------------|--------|
| Observability & Logging | Loki, Promtail, Prometheus, Grafana | ✅ |
| Autoscaling | Kafka lag autoscaler script | ✅ |
| Security Hardening | TLS, secrets, overlay networks | ✅ |
| Resilience Drill | chaos.yml + Swarm self-healing | ✅ |
| Documentation | Complete README | ✅ |

---

## Author
**Le'Shawn Sears**
