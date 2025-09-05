# CS 5287 - Cloud Computing (CA0-CA4)

This repository documents the progressive development of a cloud-hosted IoT data pipeline across five modalities.  
The pipeline remains conceptually the same **Producer → Kafka Pub/Sub Hub → Processor → MongoDB** but the deployment model and operational
practices evolve at each stage.  

The goal is to gain end-to-end experience with multiple cloud approaches, moving from manual setup to automation,
orchestration, observability, and finally multi-cloud strategies.  

---

## Roadmap

### [CA0 – Manual Deployment](./CA0)
- **Focus**: Learn each component end-to-end by provisioning and configuring VMs by hand.  
- **Environment**: AWS Free Tier (EC2, Ubuntu 22.04).  
- **Stack**: Kafka 3.7.0 + ZooKeeper, MongoDB 6.0, Python 3.12 Producer & Processor.  
- **Outcome**: Demonstrated full data flow with screenshots, network diagram, and demo video.  
