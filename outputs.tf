output "instance_public_ip" {
  description = "EC2 인스턴스의 퍼블릭 IP"
  value       = aws_instance.app_server.public_ip
}