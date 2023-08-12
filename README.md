# Oracle Cloud Minecraft Server Automation

This repository contains a barebone, deployment of a Minecraft Server using Oracle Cloud.

> The configuration in here, by default, creates an instance that abides by the **Always Free** Tier that Oracle Cloud provides for all customers. Setting different configurations to go past the **Always Free** Tier is allowed, but the price of said deployment will **vary**.

## Goal of Deployment

Since I created a more complex deployment over [here](https://github.com/maishiroma/MCServerBootstrap), I wanted to see if I can just create a simpler deployment that can manage a Minecraft server using `systemd`. This will greatly simplify managing the instance since you would only need to know how to use `systemd` services to manage the server lifecycle.

### Features

- Managing `minecraft` service on instance via `systemd`
- Backup and Restore from Backups done via Scripts (currently need to call manually on instance)
- Can auto setup either **vanilla** or a **Forge** server
- Automatic bootstrap and startup of Minecraft Server
- Cost Saving Module; Bare Minimum Setup to get going
- Ability to sync mods from Object Storage
- Ability to initially pass a custom server.properties and an ops.json to the instance
- Auto Backup via CronJob (Defaults to once a week on Friday at 3PM)

## Architecture Diagram

This deployment creates the following items:
- One Identity Compartment to group all of these deployments into for easier management
    - One Dynamic Group with a Dynamic Policy to access Object Storage Buckets
- An Object Storage Bucket
- An instance configuration
- An instance pool
- A VPC with
    - One public subnet
    - One Internet Gateway
    - One Route Table
    - One Security List that allows for:
        - Port 22 Traffic
        - Port 25565 Traffic

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | > 0.12 |
| <a name="requirement_oci"></a> [oci](#requirement\_oci) | = 4.121.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | = 3.5.1 |
| <a name="requirement_template"></a> [template](#requirement\_template) | = 2.2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_oci"></a> [oci](#provider\_oci) | = 4.121.0 |
| <a name="provider_random"></a> [random](#provider\_random) | = 3.5.1 |
| <a name="provider_template"></a> [template](#provider\_template) | = 2.2.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [oci_core_default_route_table.self](https://registry.terraform.io/providers/oracle/oci/4.121.0/docs/resources/core_default_route_table) | resource |
| [oci_core_instance_configuration.self](https://registry.terraform.io/providers/oracle/oci/4.121.0/docs/resources/core_instance_configuration) | resource |
| [oci_core_instance_pool.self](https://registry.terraform.io/providers/oracle/oci/4.121.0/docs/resources/core_instance_pool) | resource |
| [oci_core_internet_gateway.self](https://registry.terraform.io/providers/oracle/oci/4.121.0/docs/resources/core_internet_gateway) | resource |
| [oci_core_security_list.self](https://registry.terraform.io/providers/oracle/oci/4.121.0/docs/resources/core_security_list) | resource |
| [oci_core_subnet.public](https://registry.terraform.io/providers/oracle/oci/4.121.0/docs/resources/core_subnet) | resource |
| [oci_core_vcn.self](https://registry.terraform.io/providers/oracle/oci/4.121.0/docs/resources/core_vcn) | resource |
| [oci_identity_compartment.self](https://registry.terraform.io/providers/oracle/oci/4.121.0/docs/resources/identity_compartment) | resource |
| [oci_identity_dynamic_group.self](https://registry.terraform.io/providers/oracle/oci/4.121.0/docs/resources/identity_dynamic_group) | resource |
| [oci_identity_policy.self](https://registry.terraform.io/providers/oracle/oci/4.121.0/docs/resources/identity_policy) | resource |
| [oci_objectstorage_bucket.self](https://registry.terraform.io/providers/oracle/oci/4.121.0/docs/resources/objectstorage_bucket) | resource |
| [random_string.unique](https://registry.terraform.io/providers/hashicorp/random/3.5.1/docs/resources/string) | resource |
| [oci_core_instance.self](https://registry.terraform.io/providers/oracle/oci/4.121.0/docs/data-sources/core_instance) | data source |
| [oci_core_instance_pool_instances.self](https://registry.terraform.io/providers/oracle/oci/4.121.0/docs/data-sources/core_instance_pool_instances) | data source |
| [oci_objectstorage_namespace.self](https://registry.terraform.io/providers/oracle/oci/4.121.0/docs/data-sources/objectstorage_namespace) | data source |
| [template_cloudinit_config.self](https://registry.terraform.io/providers/hashicorp/template/2.2.0/docs/data-sources/cloudinit_config) | data source |
| [template_file.fact_file](https://registry.terraform.io/providers/hashicorp/template/2.2.0/docs/data-sources/file) | data source |
| [template_file.minecraft_service](https://registry.terraform.io/providers/hashicorp/template/2.2.0/docs/data-sources/file) | data source |
| [template_file.modded_user_jvm_args](https://registry.terraform.io/providers/hashicorp/template/2.2.0/docs/data-sources/file) | data source |
| [template_file.rclone_conf](https://registry.terraform.io/providers/hashicorp/template/2.2.0/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_ip_addresses"></a> [admin\_ip\_addresses](#input\_admin\_ip\_addresses) | List of IPs to allow SSH access | `list(string)` | `[]` | no |
| <a name="input_availability_domain"></a> [availability\_domain](#input\_availability\_domain) | The az to put the instance in. Note that this default is for us-sanjose-1 | `string` | `"gEpX:US-SANJOSE-1-AD-1"` | no |
| <a name="input_backup_crontime"></a> [backup\_crontime](#input\_backup\_crontime) | The time in crontime for auto backups to run via a cronjob. Defaults to once a week on Friday at 3PM | `string` | `"0 15 * * 5"` | no |
| <a name="input_custom_ops_json_path"></a> [custom\_ops\_json\_path](#input\_custom\_ops\_json\_path) | The path to a custom ops.json that is used for the server. Leave blank to not use assign anyone ops | `string` | `""` | no |
| <a name="input_custom_server_properties_path"></a> [custom\_server\_properties\_path](#input\_custom\_server\_properties\_path) | The path to a custom server.properites that is used for this server. Leave blank to use the default | `string` | `""` | no |
| <a name="input_existing_pub_subnet"></a> [existing\_pub\_subnet](#input\_existing\_pub\_subnet) | The ID of an existing public subnet. If left at "", will create a new VPN and associate this instance to it | `string` | `""` | no |
| <a name="input_game_ip_addresses"></a> [game\_ip\_addresses](#input\_game\_ip\_addresses) | List of IPs to allow minecraft access | `list(string)` | `[]` | no |
| <a name="input_is_modded"></a> [is\_modded](#input\_is\_modded) | Is this server a modded one? Defaults to False. | `bool` | `false` | no |
| <a name="input_max_memory"></a> [max\_memory](#input\_max\_memory) | The max amount of RAM allocate to the server | `string` | `"5G"` | no |
| <a name="input_min_memory"></a> [min\_memory](#input\_min\_memory) | The min amount of RAM allocate to the server | `string` | `"1G"` | no |
| <a name="input_minecraft_server_jar_download_url"></a> [minecraft\_server\_jar\_download\_url](#input\_minecraft\_server\_jar\_download\_url) | The URL that allows one to download the server JAR of their choice. Defaults to a vanilla MC server. | `string` | `"https://piston-data.mojang.com/v1/objects/8f3112a1049751cc472ec13e397eade5336ca7ae/server.jar"` | no |
| <a name="input_parent_compartment_id"></a> [parent\_compartment\_id](#input\_parent\_compartment\_id) | The parent compartment to associate the deployment's compartment. | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | The name of this project | `string` | `"mc-server"` | no |
| <a name="input_pub_key"></a> [pub\_key](#input\_pub\_key) | The public key to associate on the instance in order to provide SSH access | `string` | n/a | yes |
| <a name="input_pub_subnet_block"></a> [pub\_subnet\_block](#input\_pub\_subnet\_block) | The CIDR block to use for the subnet | `string` | `"10.0.0.0/24"` | no |
| <a name="input_region_name"></a> [region\_name](#input\_region\_name) | The name of the region | `string` | `"us-sanjose-1"` | no |
| <a name="input_vm_image"></a> [vm\_image](#input\_vm\_image) | The image ID that is used for the VM. Note that this default is for us-sanjose-1. | `string` | `"ocid1.image.oc1.us-sanjose-1.aaaaaaaaxnfbpr6wcawvbgx56ls5v2lndcmp7q3e7guu3rkrwcfhecouxslq"` | no |
| <a name="input_vm_shape"></a> [vm\_shape](#input\_vm\_shape) | The shape of the VM. The default is part of the Always Free Tier | `string` | `"VM.Standard.A1.Flex"` | no |
| <a name="input_vm_specs"></a> [vm\_specs](#input\_vm\_specs) | The specs of the VM. Note that the default is part of the Always Free Tier | `map(string)` | <pre>{<br>  "cpus": "2",<br>  "memory": "6"<br>}</pre> | no |
| <a name="input_vpc_cidr_block"></a> [vpc\_cidr\_block](#input\_vpc\_cidr\_block) | The CIDR block to use for the VPC | `string` | `"10.0.0.0/16"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_backup_bucket_name"></a> [backup\_bucket\_name](#output\_backup\_bucket\_name) | The name of the bucket that holds world backups and mods for the server |
| <a name="output_pub_subnet_id"></a> [pub\_subnet\_id](#output\_pub\_subnet\_id) | The OICD of the created public subnet, if it exists. |
| <a name="output_server_public_ip"></a> [server\_public\_ip](#output\_server\_public\_ip) | The public IP of the created server in the instance pool. |

## Steps to Deploy

1. Make sure you have the following already configured on your computer:
- `terraform` >= 0.12
- Oracle Cloud Credentials
    - To authenticate `terraform` with your OCI account, see [this](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/terraformproviderconfiguration.htm)
1. Create a new `terraform` root with the following configuration, making sure to fill in the values for "...":

```tf
provider "oci" {
  region           = "..."
  # There are a multitude of ways to authenticate to OCI;
  # please see the docs for your preferred method.
}

terraform {
  # The state is stored locally
  backend "local" {
    path = "./terraform.tfstate"
  }
}


module "mc_server" {
  # This sources the module to whatever is on latest
  # You can either use a tag or alternatively clone this repo and source
  # this module as a local module for more stability
  source = "git@github.com:maishiroma/OracleMCServer.git?ref=main"

  parent_compartment_id = "..."
  region_name           = "..."

  pub_key = ""

  admin_ip_addresses = ["..."]
  game_ip_addresses  = ["..."]
}
```

1. Run `terraform init` and `terraform plan` to confirm the deployment
1. If everything looks good, `terraform apply`

## Managing

All of these need to be done via `ssh` into the instance

- Restarting Server: `sudo systemctl restart minecraft`
- Stopping Server: `sudo systemctl stop minecraft`
- Status of Server: `sudo systemctl status minecraft`
- Creating a world backup: `cd /etc && sudo ./backup.sh`
    - World Backups are saved in the created Object Bucket that is made
- Restoring from a named backup: `cd /etc && sudo ./restore_backup.sh <name_of_backup>`
- Syncing Mods from bucket: `cd /etc && sudo ./mod_refresh.sh`
    - This is available if `server_type` is set to something besides `vanilla`
- Adjusting the server.properites and/or ops.json
    - Make changes in TF and apply them to the instance
    - Reboot instance

All of the following are services that are done via the OCI Console:
- Shutting Down Instance: `OCI Console -> Instances -> Instance Pools -> Select Instance Pool, mc-server-XXXX -> Stop`
    - This is optimal when you want to save funds on the instance if no one is using it at the current moment

## Cleaning Up

In the case that the server is no longer needed, the following should be done:
1. **MAKE A BACKUP OF THE WORLD on the instance** using the backup script.
1. Download said backup from the object storage to your local computer.
1. Run `terraform destroy` on your existing TF code that you used earlier
1. Confirm and all resources for the server are now removed