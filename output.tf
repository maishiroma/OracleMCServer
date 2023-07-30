output "pub_subnet_id" {
    description = "The OICD of the created public subnet, if it exists."
    value = oci_core_subnet.public.*.id
}