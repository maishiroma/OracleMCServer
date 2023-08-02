[oos]
type = oracleobjectstorage
namespace = ${bucket_namespace}
env_auth = false
compartment = ${compartment_id}
region = ${region_name}
endpoint = https://${bucket_namespace}.compat.objectstorage.${region_name}.oraclecloud.com
provider = instance_principal_auth