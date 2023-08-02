output "pub_subnet_id" {
  description = "The OICD of the created public subnet, if it exists."
  value       = oci_core_subnet.public.*.id
}

output "server_public_ip" {
  description = "The public IP of the created server in the instance pool."
  value       = data.oci_core_instance.self.public_ip
}

output "backup_bucket_name" {
  description = "The name of the bucket that holds world backups and mods for the server"
  value       = oci_objectstorage_bucket.self.name
}