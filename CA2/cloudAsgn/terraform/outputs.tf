# ---------------------------
# Public DNS for EC2s
# ---------------------------
output "kafka_dns" { value = aws_instance.kafka_vm.public_dns }
output "db_dns" { value = aws_instance.db_vm.public_dns }
output "processor_dns" { value = aws_instance.processor_vm.public_dns }
output "producer_dns" { value = aws_instance.producer_vm.public_dns }

