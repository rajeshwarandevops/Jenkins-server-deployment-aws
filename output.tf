output "jenkins-public-ip" {
  value = aws_instance.jenkins.public_ip
}