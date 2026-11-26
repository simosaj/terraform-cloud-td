# TD 2 — Terraform sur GCP et AWS

Dans chaque VPC, le nom privé `app.td.internal.` renvoie les adresses des deux VM. Une application installée sur une VM peut se connecter à MySQL avec ses propres identifiants. Les VM sont réparties entre deux zones. Le DNS distribue leurs adresses sans vérifier leur état de santé. La base du TD reste mono-zone.

| Ressource | Google Cloud · europe-west9 | AWS · eu-west-3 |
| --- | --- | --- |
| Réseau | VPC et sous-réseau régional | VPC et deux sous-réseaux dans deux zones |
| Calcul | Deux VM Debian 12 sur Compute Engine | Deux instances EC2 Amazon Linux 2023 |
| Base privée | Cloud SQL pour MySQL, reliée au VPC par Private Services Access | RDS pour MySQL, port 3306 accessible depuis le groupe de sécurité des VM |
| DNS | Zone privée Cloud DNS | Zone privée Route 53 |
| Réplication des VM | `count` et alternance entre zones a et b | `count` et alternance entre les sous-réseaux |

Les dossiers [foundation-gcp](foundation-gcp) et [foundation-aws](foundation-aws) sont les points d’entrée. Chacun appelle un [module réutilisable](modules). Pour une autre application, appeler le module avec un autre préfixe `name` et une autre `dns_zone`.

## Organisation

Chaque dossier `foundation-*` appelle un module dans `modules/`.

| Fichier | Rôle |
| --- | --- |
| `main.tf` | Configure le provider et appelle le module. |
| `variables.tf` | Déclare les paramètres du TD. |
| `outputs.tf` | Affiche les adresses et les identifiants après le déploiement. |
| `versions.tf` | Déclare les versions compatibles de Terraform et du provider. |
| `.terraform.lock.hcl` | Conserve la version choisie et les empreintes du provider. |

Dans les modules, les ressources sont rangées dans `network.tf`, `compute.tf`, `database.tf` et `dns.tf`.

## Choix réalisés

Le méta-argument `count` permet de passer d’une VM à plusieurs VM. `count.index` numérote les VM, et `element` alterne entre les deux zones. Deux VM apportent de la redondance, mais une panne nécessite encore une intervention puisque le DNS ne teste pas leur disponibilité.

Cloud SQL utilise un réseau géré par Google, relié au VPC par Private Services Access. Sur AWS, RDS utilise les sous-réseaux du VPC et son groupe de sécurité autorise MySQL depuis les VM.

Les variables `name`, `dns_zone`, `vm_count` et `region` sont accessibles depuis les deux dossiers principaux. Les zones AWS sont déduites de la région avec les suffixes a et b. Le module GCP utilise les suffixes a et b. Il faut vérifier que ces zones existent avant de choisir une autre région.

Pour changer le préfixe et le nombre de VM, lancer dans le dossier du fournisseur choisi.

```sh
terraform plan -var="name=mon-app" -var="vm_count=3"
```

Les deux modules exposent `vpc_id`, `vm_private_ips`, `database_host` et `app_dns`. Après un déploiement, `terraform output` les affiche. La sortie `database_host` donne l’adresse à utiliser dans la configuration de l’application.

## Reproduire le plan GCP

Exécuter ces commandes Bash depuis la racine avec Terraform 1.11.4 et Python 3. Placer le fichier fourni par l’école dans un dossier privé situé hors du dépôt. Adapter le chemin à son emplacement.

```bash
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/.config/td-cloud/student.json"
export TF_VAR_project_id="$(python3 -c 'import json, os; print(json.load(open(os.environ["GOOGLE_APPLICATION_CREDENTIALS"]))["project_id"])')"
cd TD/2_terraform/foundation-gcp
terraform init
terraform validate
terraform plan
```

Pour un déploiement, le projet doit autoriser Compute Engine, Cloud DNS, Cloud SQL Admin et Service Networking. Le peering relie le réseau de Cloud SQL au VPC des VM. Les VM et MySQL utilisent uniquement des IP privées.

## Reproduire le plan AWS

Ouvrir une autre session à la racine du dépôt. Choisir le profil AWS configuré pour le cours si plusieurs comptes sont disponibles.

```bash
cd TD/2_terraform/foundation-aws
terraform init
terraform validate
terraform plan
```

RDS utilise Secrets Manager pour générer le mot de passe principal. Pour comparer les deux plans avec une seule VM, exécuter `terraform plan -var="vm_count=1"` dans l’un des deux dossiers.

## Plans de démonstration

Depuis la racine, `bash scripts/plan-demo.sh` valide et planifie successivement les étapes provider, réseau, première VM, base, DNS et deuxième VM sur un état vide. Le script utilise un projet fictif et des paramètres hors ligne. Il ne vérifie donc ni les autorisations, ni les quotas d’un compte cloud. Le workflow **Terraform TD** lance le même script et conserve sa sortie intégrale dans l’artefact **plans-terraform**. Aucune étape ne lance `terraform apply`.

## Résultats vérifiés le 26 novembre 2026

Le workflow a exécuté avec succès `terraform fmt -check -recursive`, puis `terraform validate` et `terraform plan` à chacune des six étapes sur les deux providers. Les plans utilisent un état vide et les paramètres de démonstration décrits ci-dessus.

| Étape | GCP · créations | AWS · créations |
| --- | --- | --- |
| Provider seul | 0 | 0 |
| VPC et sous-réseaux | 2 | 3 |
| Première VM et ses dépendances | 3 | 6 |
| Base de données et réseau privé | 6 | 11 |
| Zone et enregistrement DNS | 8 | 13 |
| Deuxième VM avec `count` | 9 | 14 |

Tous les plans annoncent zéro modification et zéro suppression.

[Exécution GitHub Actions vérifiée](https://github.com/simosaj/terraform-cloud-td/actions/runs/45822545259)

### Plan GCP complet

<details>
<summary>Afficher le plan GCP</summary>

```text
Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # module.foundation.google_compute_global_address.sql_range will be created
  + resource "google_compute_global_address" "sql_range" {
      + address            = (known after apply)
      + address_type       = "INTERNAL"
      + creation_timestamp = (known after apply)
      + effective_labels   = {
          + "goog-terraform-provisioned" = "true"
        }
      + id                 = (known after apply)
      + label_fingerprint  = (known after apply)
      + name               = "td-cloud-sql-range"
      + network            = (known after apply)
      + prefix_length      = 16
      + project            = "td-demo-project"
      + purpose            = "VPC_PEERING"
      + self_link          = (known after apply)
      + terraform_labels   = {
          + "goog-terraform-provisioned" = "true"
        }
    }

  # module.foundation.google_compute_instance.app[0] will be created
  + resource "google_compute_instance" "app" {
      + can_ip_forward       = false
      + cpu_platform         = (known after apply)
      + creation_timestamp   = (known after apply)
      + current_status       = (known after apply)
      + deletion_protection  = false
      + effective_labels     = {
          + "goog-terraform-provisioned" = "true"
        }
      + id                   = (known after apply)
      + instance_id          = (known after apply)
      + label_fingerprint    = (known after apply)
      + machine_type         = "e2-micro"
      + metadata_fingerprint = (known after apply)
      + min_cpu_platform     = (known after apply)
      + name                 = "td-cloud-vm-1"
      + project              = "td-demo-project"
      + self_link            = (known after apply)
      + tags_fingerprint     = (known after apply)
      + terraform_labels     = {
          + "goog-terraform-provisioned" = "true"
        }
      + zone                 = "europe-west9-a"

      + boot_disk {
          + auto_delete                = true
          + device_name                = (known after apply)
          + disk_encryption_key_sha256 = (known after apply)
          + kms_key_self_link          = (known after apply)
          + mode                       = "READ_WRITE"
          + source                     = (known after apply)

          + initialize_params {
              + image                  = "debian-cloud/debian-12"
              + labels                 = (known after apply)
              + provisioned_iops       = (known after apply)
              + provisioned_throughput = (known after apply)
              + resource_policies      = (known after apply)
              + size                   = 10
              + type                   = (known after apply)
            }
        }

      + confidential_instance_config (known after apply)

      + guest_accelerator (known after apply)

      + network_interface {
          + internal_ipv6_prefix_length = (known after apply)
          + ipv6_access_type            = (known after apply)
          + ipv6_address                = (known after apply)
          + name                        = (known after apply)
          + network                     = (known after apply)
          + network_ip                  = (known after apply)
          + stack_type                  = (known after apply)
          + subnetwork                  = (known after apply)
          + subnetwork_project          = (known after apply)
        }

      + reservation_affinity (known after apply)

      + scheduling (known after apply)
    }

  # module.foundation.google_compute_instance.app[1] will be created
  + resource "google_compute_instance" "app" {
      + can_ip_forward       = false
      + cpu_platform         = (known after apply)
      + creation_timestamp   = (known after apply)
      + current_status       = (known after apply)
      + deletion_protection  = false
      + effective_labels     = {
          + "goog-terraform-provisioned" = "true"
        }
      + id                   = (known after apply)
      + instance_id          = (known after apply)
      + label_fingerprint    = (known after apply)
      + machine_type         = "e2-micro"
      + metadata_fingerprint = (known after apply)
      + min_cpu_platform     = (known after apply)
      + name                 = "td-cloud-vm-2"
      + project              = "td-demo-project"
      + self_link            = (known after apply)
      + tags_fingerprint     = (known after apply)
      + terraform_labels     = {
          + "goog-terraform-provisioned" = "true"
        }
      + zone                 = "europe-west9-b"

      + boot_disk {
          + auto_delete                = true
          + device_name                = (known after apply)
          + disk_encryption_key_sha256 = (known after apply)
          + kms_key_self_link          = (known after apply)
          + mode                       = "READ_WRITE"
          + source                     = (known after apply)

          + initialize_params {
              + image                  = "debian-cloud/debian-12"
              + labels                 = (known after apply)
              + provisioned_iops       = (known after apply)
              + provisioned_throughput = (known after apply)
              + resource_policies      = (known after apply)
              + size                   = 10
              + type                   = (known after apply)
            }
        }

      + confidential_instance_config (known after apply)

      + guest_accelerator (known after apply)

      + network_interface {
          + internal_ipv6_prefix_length = (known after apply)
          + ipv6_access_type            = (known after apply)
          + ipv6_address                = (known after apply)
          + name                        = (known after apply)
          + network                     = (known after apply)
          + network_ip                  = (known after apply)
          + stack_type                  = (known after apply)
          + subnetwork                  = (known after apply)
          + subnetwork_project          = (known after apply)
        }

      + reservation_affinity (known after apply)

      + scheduling (known after apply)
    }

  # module.foundation.google_compute_network.app will be created
  + resource "google_compute_network" "app" {
      + auto_create_subnetworks                   = false
      + delete_default_routes_on_create           = false
      + gateway_ipv4                              = (known after apply)
      + id                                        = (known after apply)
      + internal_ipv6_range                       = (known after apply)
      + mtu                                       = (known after apply)
      + name                                      = "td-cloud-vpc"
      + network_firewall_policy_enforcement_order = "AFTER_CLASSIC_FIREWALL"
      + numeric_id                                = (known after apply)
      + project                                   = "td-demo-project"
      + routing_mode                              = (known after apply)
      + self_link                                 = (known after apply)
    }

  # module.foundation.google_compute_subnetwork.app will be created
  + resource "google_compute_subnetwork" "app" {
      + creation_timestamp         = (known after apply)
      + external_ipv6_prefix       = (known after apply)
      + fingerprint                = (known after apply)
      + gateway_address            = (known after apply)
      + id                         = (known after apply)
      + internal_ipv6_prefix       = (known after apply)
      + ip_cidr_range              = "10.20.1.0/24"
      + ipv6_cidr_range            = (known after apply)
      + name                       = "td-cloud-subnet"
      + network                    = (known after apply)
      + private_ip_google_access   = (known after apply)
      + private_ipv6_google_access = (known after apply)
      + project                    = "td-demo-project"
      + purpose                    = (known after apply)
      + region                     = "europe-west9"
      + self_link                  = (known after apply)
      + stack_type                 = (known after apply)

      + secondary_ip_range (known after apply)
    }

  # module.foundation.google_dns_managed_zone.app will be created
  + resource "google_dns_managed_zone" "app" {
      + creation_time    = (known after apply)
      + description      = "Managed by Terraform"
      + dns_name         = "td.internal."
      + effective_labels = {
          + "goog-terraform-provisioned" = "true"
        }
      + force_destroy    = false
      + id               = (known after apply)
      + managed_zone_id  = (known after apply)
      + name             = "td-cloud-zone"
      + name_servers     = (known after apply)
      + project          = "td-demo-project"
      + terraform_labels = {
          + "goog-terraform-provisioned" = "true"
        }
      + visibility       = "private"

      + cloud_logging_config (known after apply)

      + dnssec_config (known after apply)

      + private_visibility_config {
          + networks {
              + network_url = (known after apply)
            }
        }
    }

  # module.foundation.google_dns_record_set.app will be created
  + resource "google_dns_record_set" "app" {
      + id           = (known after apply)
      + managed_zone = "td-cloud-zone"
      + name         = "app.td.internal."
      + project      = "td-demo-project"
      + rrdatas      = (known after apply)
      + ttl          = 60
      + type         = "A"
    }

  # module.foundation.google_service_networking_connection.sql will be created
  + resource "google_service_networking_connection" "sql" {
      + id                      = (known after apply)
      + network                 = (known after apply)
      + peering                 = (known after apply)
      + reserved_peering_ranges = [
          + "td-cloud-sql-range",
        ]
      + service                 = "servicenetworking.googleapis.com"
    }

  # module.foundation.google_sql_database_instance.app will be created
  + resource "google_sql_database_instance" "app" {
      + available_maintenance_versions = (known after apply)
      + connection_name                = (known after apply)
      + database_version               = "MYSQL_8_0"
      + deletion_protection            = false
      + dns_name                       = (known after apply)
      + encryption_key_name            = (known after apply)
      + first_ip_address               = (known after apply)
      + id                             = (known after apply)
      + instance_type                  = (known after apply)
      + ip_address                     = (known after apply)
      + maintenance_version            = (known after apply)
      + master_instance_name           = (known after apply)
      + name                           = "td-cloud-mysql"
      + private_ip_address             = (known after apply)
      + project                        = "td-demo-project"
      + psc_service_attachment_link    = (known after apply)
      + public_ip_address              = (known after apply)
      + region                         = "europe-west9"
      + replica_names                  = (known after apply)
      + self_link                      = (known after apply)
      + server_ca_cert                 = (sensitive value)
      + service_account_email_address  = (known after apply)

      + replica_configuration (known after apply)

      + settings {
          + activation_policy     = "ALWAYS"
          + availability_type     = "ZONAL"
          + connector_enforcement = (known after apply)
          + disk_autoresize       = true
          + disk_autoresize_limit = 0
          + disk_size             = (known after apply)
          + disk_type             = "PD_SSD"
          + edition               = "ENTERPRISE"
          + pricing_plan          = "PER_USE"
          + tier                  = "db-f1-micro"
          + user_labels           = (known after apply)
          + version               = (known after apply)

          + backup_configuration (known after apply)

          + data_cache_config (known after apply)

          + insights_config (known after apply)

          + ip_configuration {
              + ipv4_enabled    = false
              + private_network = (known after apply)
              + server_ca_mode  = (known after apply)
              + ssl_mode        = (known after apply)
            }

          + location_preference (known after apply)
        }
    }

Plan: 9 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + app_dns        = "app.td.internal."
  + database_host  = (known after apply)
  + vm_private_ips = [
      + (known after apply),
      + (known after apply),
    ]
  + vpc_id         = (known after apply)
```

</details>

### Plan AWS complet

<details>
<summary>Afficher le plan AWS</summary>

```text
Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # module.foundation.aws_db_instance.app will be created
  + resource "aws_db_instance" "app" {
      + address                               = (known after apply)
      + allocated_storage                     = 20
      + apply_immediately                     = false
      + arn                                   = (known after apply)
      + auto_minor_version_upgrade            = true
      + availability_zone                     = (known after apply)
      + backup_retention_period               = (known after apply)
      + backup_target                         = (known after apply)
      + backup_window                         = (known after apply)
      + ca_cert_identifier                    = (known after apply)
      + character_set_name                    = (known after apply)
      + copy_tags_to_snapshot                 = false
      + database_insights_mode                = (known after apply)
      + db_name                               = (known after apply)
      + db_subnet_group_name                  = "td-cloud-db"
      + dedicated_log_volume                  = false
      + delete_automated_backups              = true
      + domain_fqdn                           = (known after apply)
      + endpoint                              = (known after apply)
      + engine                                = "mysql"
      + engine_lifecycle_support              = (known after apply)
      + engine_version                        = (known after apply)
      + engine_version_actual                 = (known after apply)
      + hosted_zone_id                        = (known after apply)
      + id                                    = (known after apply)
      + identifier                            = "td-cloud-mysql"
      + identifier_prefix                     = (known after apply)
      + instance_class                        = "db.t4g.micro"
      + iops                                  = (known after apply)
      + kms_key_id                            = (known after apply)
      + latest_restorable_time                = (known after apply)
      + license_model                         = (known after apply)
      + listener_endpoint                     = (known after apply)
      + maintenance_window                    = (known after apply)
      + manage_master_user_password           = true
      + master_user_secret                    = (known after apply)
      + master_user_secret_kms_key_id         = (known after apply)
      + monitoring_interval                   = 0
      + monitoring_role_arn                   = (known after apply)
      + multi_az                              = (known after apply)
      + nchar_character_set_name              = (known after apply)
      + network_type                          = (known after apply)
      + option_group_name                     = (known after apply)
      + parameter_group_name                  = (known after apply)
      + password_wo                           = (write-only attribute)
      + performance_insights_enabled          = false
      + performance_insights_kms_key_id       = (known after apply)
      + performance_insights_retention_period = (known after apply)
      + port                                  = (known after apply)
      + publicly_accessible                   = false
      + region                                = "eu-west-3"
      + replica_mode                          = (known after apply)
      + replicas                              = (known after apply)
      + resource_id                           = (known after apply)
      + skip_final_snapshot                   = true
      + snapshot_identifier                   = (known after apply)
      + status                                = (known after apply)
      + storage_encrypted                     = true
      + storage_throughput                    = (known after apply)
      + storage_type                          = (known after apply)
      + tags_all                              = (known after apply)
      + timezone                              = (known after apply)
      + username                              = "tdadmin"
      + vpc_security_group_ids                = (known after apply)
    }

  # module.foundation.aws_db_subnet_group.app will be created
  + resource "aws_db_subnet_group" "app" {
      + arn                     = (known after apply)
      + description             = "Managed by Terraform"
      + id                      = (known after apply)
      + name                    = "td-cloud-db"
      + name_prefix             = (known after apply)
      + region                  = "eu-west-3"
      + subnet_ids              = (known after apply)
      + supported_network_types = (known after apply)
      + tags_all                = (known after apply)
      + vpc_id                  = (known after apply)
    }

  # module.foundation.aws_instance.app[0] will be created
  + resource "aws_instance" "app" {
      + ami                                  = (known after apply)
      + arn                                  = (known after apply)
      + associate_public_ip_address          = (known after apply)
      + availability_zone                    = (known after apply)
      + disable_api_stop                     = (known after apply)
      + disable_api_termination              = (known after apply)
      + ebs_optimized                        = (known after apply)
      + enable_primary_ipv6                  = (known after apply)
      + get_password_data                    = false
      + host_id                              = (known after apply)
      + host_resource_group_arn              = (known after apply)
      + iam_instance_profile                 = (known after apply)
      + id                                   = (known after apply)
      + instance_initiated_shutdown_behavior = (known after apply)
      + instance_lifecycle                   = (known after apply)
      + instance_state                       = (known after apply)
      + instance_type                        = (known after apply)
      + ipv6_address_count                   = (known after apply)
      + ipv6_addresses                       = (known after apply)
      + key_name                             = (known after apply)
      + monitoring                           = (known after apply)
      + outpost_arn                          = (known after apply)
      + password_data                        = (known after apply)
      + placement_group                      = (known after apply)
      + placement_partition_number           = (known after apply)
      + primary_network_interface_id         = (known after apply)
      + private_dns                          = (known after apply)
      + private_ip                           = (known after apply)
      + public_dns                           = (known after apply)
      + public_ip                            = (known after apply)
      + region                               = "eu-west-3"
      + secondary_private_ips                = (known after apply)
      + security_groups                      = (known after apply)
      + source_dest_check                    = true
      + spot_instance_request_id             = (known after apply)
      + subnet_id                            = (known after apply)
      + tags                                 = {
          + "Name" = "td-cloud-vm-1"
        }
      + tags_all                             = {
          + "Name" = "td-cloud-vm-1"
        }
      + tenancy                              = (known after apply)
      + user_data_base64                     = (known after apply)
      + user_data_replace_on_change          = false
      + vpc_security_group_ids               = (known after apply)

      + capacity_reservation_specification (known after apply)

      + cpu_options (known after apply)

      + ebs_block_device (known after apply)

      + enclave_options (known after apply)

      + ephemeral_block_device (known after apply)

      + instance_market_options (known after apply)

      + launch_template {
          + id      = (known after apply)
          + name    = (known after apply)
          + version = (known after apply)
        }

      + maintenance_options (known after apply)

      + metadata_options (known after apply)

      + network_interface (known after apply)

      + private_dns_name_options (known after apply)

      + root_block_device (known after apply)
    }

  # module.foundation.aws_instance.app[1] will be created
  + resource "aws_instance" "app" {
      + ami                                  = (known after apply)
      + arn                                  = (known after apply)
      + associate_public_ip_address          = (known after apply)
      + availability_zone                    = (known after apply)
      + disable_api_stop                     = (known after apply)
      + disable_api_termination              = (known after apply)
      + ebs_optimized                        = (known after apply)
      + enable_primary_ipv6                  = (known after apply)
      + get_password_data                    = false
      + host_id                              = (known after apply)
      + host_resource_group_arn              = (known after apply)
      + iam_instance_profile                 = (known after apply)
      + id                                   = (known after apply)
      + instance_initiated_shutdown_behavior = (known after apply)
      + instance_lifecycle                   = (known after apply)
      + instance_state                       = (known after apply)
      + instance_type                        = (known after apply)
      + ipv6_address_count                   = (known after apply)
      + ipv6_addresses                       = (known after apply)
      + key_name                             = (known after apply)
      + monitoring                           = (known after apply)
      + outpost_arn                          = (known after apply)
      + password_data                        = (known after apply)
      + placement_group                      = (known after apply)
      + placement_partition_number           = (known after apply)
      + primary_network_interface_id         = (known after apply)
      + private_dns                          = (known after apply)
      + private_ip                           = (known after apply)
      + public_dns                           = (known after apply)
      + public_ip                            = (known after apply)
      + region                               = "eu-west-3"
      + secondary_private_ips                = (known after apply)
      + security_groups                      = (known after apply)
      + source_dest_check                    = true
      + spot_instance_request_id             = (known after apply)
      + subnet_id                            = (known after apply)
      + tags                                 = {
          + "Name" = "td-cloud-vm-2"
        }
      + tags_all                             = {
          + "Name" = "td-cloud-vm-2"
        }
      + tenancy                              = (known after apply)
      + user_data_base64                     = (known after apply)
      + user_data_replace_on_change          = false
      + vpc_security_group_ids               = (known after apply)

      + capacity_reservation_specification (known after apply)

      + cpu_options (known after apply)

      + ebs_block_device (known after apply)

      + enclave_options (known after apply)

      + ephemeral_block_device (known after apply)

      + instance_market_options (known after apply)

      + launch_template {
          + id      = (known after apply)
          + name    = (known after apply)
          + version = (known after apply)
        }

      + maintenance_options (known after apply)

      + metadata_options (known after apply)

      + network_interface (known after apply)

      + private_dns_name_options (known after apply)

      + root_block_device (known after apply)
    }

  # module.foundation.aws_launch_template.app will be created
  + resource "aws_launch_template" "app" {
      + arn                    = (known after apply)
      + default_version        = (known after apply)
      + id                     = (known after apply)
      + image_id               = "resolve:ssm:/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
      + instance_type          = "t3.micro"
      + latest_version         = (known after apply)
      + name                   = (known after apply)
      + name_prefix            = "td-cloud-"
      + region                 = "eu-west-3"
      + tags_all               = (known after apply)
      + vpc_security_group_ids = (known after apply)

      + metadata_options {
          + http_endpoint               = (known after apply)
          + http_protocol_ipv6          = (known after apply)
          + http_put_response_hop_limit = (known after apply)
          + http_tokens                 = "required"
          + instance_metadata_tags      = (known after apply)
        }
    }

  # module.foundation.aws_route53_record.app will be created
  + resource "aws_route53_record" "app" {
      + allow_overwrite = (known after apply)
      + fqdn            = (known after apply)
      + id              = (known after apply)
      + name            = "app.td.internal"
      + records         = (known after apply)
      + ttl             = 60
      + type            = "A"
      + zone_id         = (known after apply)
    }

  # module.foundation.aws_route53_zone.app will be created
  + resource "aws_route53_zone" "app" {
      + arn                 = (known after apply)
      + comment             = "Managed by Terraform"
      + force_destroy       = false
      + id                  = (known after apply)
      + name                = "td.internal"
      + name_servers        = (known after apply)
      + primary_name_server = (known after apply)
      + tags_all            = (known after apply)
      + zone_id             = (known after apply)

      + vpc {
          + vpc_id     = (known after apply)
          + vpc_region = (known after apply)
        }
    }

  # module.foundation.aws_security_group.db will be created
  + resource "aws_security_group" "db" {
      + arn                    = (known after apply)
      + description            = "Managed by Terraform"
      + egress                 = (known after apply)
      + id                     = (known after apply)
      + ingress                = (known after apply)
      + name                   = "td-cloud-db"
      + name_prefix            = (known after apply)
      + owner_id               = (known after apply)
      + region                 = "eu-west-3"
      + revoke_rules_on_delete = false
      + tags_all               = (known after apply)
      + vpc_id                 = (known after apply)
    }

  # module.foundation.aws_security_group.vm will be created
  + resource "aws_security_group" "vm" {
      + arn                    = (known after apply)
      + description            = "Managed by Terraform"
      + egress                 = (known after apply)
      + id                     = (known after apply)
      + ingress                = (known after apply)
      + name                   = "td-cloud-vm"
      + name_prefix            = (known after apply)
      + owner_id               = (known after apply)
      + region                 = "eu-west-3"
      + revoke_rules_on_delete = false
      + tags_all               = (known after apply)
      + vpc_id                 = (known after apply)
    }

  # module.foundation.aws_subnet.app[0] will be created
  + resource "aws_subnet" "app" {
      + arn                                            = (known after apply)
      + assign_ipv6_address_on_creation                = false
      + availability_zone                              = "eu-west-3a"
      + availability_zone_id                           = (known after apply)
      + cidr_block                                     = "10.30.1.0/24"
      + enable_dns64                                   = false
      + enable_resource_name_dns_a_record_on_launch    = false
      + enable_resource_name_dns_aaaa_record_on_launch = false
      + id                                             = (known after apply)
      + ipv6_cidr_block_association_id                 = (known after apply)
      + ipv6_native                                    = false
      + map_public_ip_on_launch                        = false
      + owner_id                                       = (known after apply)
      + private_dns_hostname_type_on_launch            = (known after apply)
      + region                                         = "eu-west-3"
      + tags                                           = {
          + "Name" = "td-cloud-subnet-1"
        }
      + tags_all                                       = {
          + "Name" = "td-cloud-subnet-1"
        }
      + vpc_id                                         = (known after apply)
    }

  # module.foundation.aws_subnet.app[1] will be created
  + resource "aws_subnet" "app" {
      + arn                                            = (known after apply)
      + assign_ipv6_address_on_creation                = false
      + availability_zone                              = "eu-west-3b"
      + availability_zone_id                           = (known after apply)
      + cidr_block                                     = "10.30.2.0/24"
      + enable_dns64                                   = false
      + enable_resource_name_dns_a_record_on_launch    = false
      + enable_resource_name_dns_aaaa_record_on_launch = false
      + id                                             = (known after apply)
      + ipv6_cidr_block_association_id                 = (known after apply)
      + ipv6_native                                    = false
      + map_public_ip_on_launch                        = false
      + owner_id                                       = (known after apply)
      + private_dns_hostname_type_on_launch            = (known after apply)
      + region                                         = "eu-west-3"
      + tags                                           = {
          + "Name" = "td-cloud-subnet-2"
        }
      + tags_all                                       = {
          + "Name" = "td-cloud-subnet-2"
        }
      + vpc_id                                         = (known after apply)
    }

  # module.foundation.aws_vpc.app will be created
  + resource "aws_vpc" "app" {
      + arn                                  = (known after apply)
      + cidr_block                           = "10.30.0.0/16"
      + default_network_acl_id               = (known after apply)
      + default_route_table_id               = (known after apply)
      + default_security_group_id            = (known after apply)
      + dhcp_options_id                      = (known after apply)
      + enable_dns_hostnames                 = true
      + enable_dns_support                   = true
      + enable_network_address_usage_metrics = (known after apply)
      + id                                   = (known after apply)
      + instance_tenancy                     = "default"
      + ipv6_association_id                  = (known after apply)
      + ipv6_cidr_block                      = (known after apply)
      + ipv6_cidr_block_network_border_group = (known after apply)
      + main_route_table_id                  = (known after apply)
      + owner_id                             = (known after apply)
      + region                               = "eu-west-3"
      + tags                                 = {
          + "Name" = "td-cloud-vpc"
        }
      + tags_all                             = {
          + "Name" = "td-cloud-vpc"
        }
    }

  # module.foundation.aws_vpc_security_group_egress_rule.mysql will be created
  + resource "aws_vpc_security_group_egress_rule" "mysql" {
      + arn                          = (known after apply)
      + from_port                    = 3306
      + id                           = (known after apply)
      + ip_protocol                  = "tcp"
      + referenced_security_group_id = (known after apply)
      + region                       = "eu-west-3"
      + security_group_id            = (known after apply)
      + security_group_rule_id       = (known after apply)
      + tags_all                     = {}
      + to_port                      = 3306
    }

  # module.foundation.aws_vpc_security_group_ingress_rule.mysql will be created
  + resource "aws_vpc_security_group_ingress_rule" "mysql" {
      + arn                          = (known after apply)
      + from_port                    = 3306
      + id                           = (known after apply)
      + ip_protocol                  = "tcp"
      + referenced_security_group_id = (known after apply)
      + region                       = "eu-west-3"
      + security_group_id            = (known after apply)
      + security_group_rule_id       = (known after apply)
      + tags_all                     = {}
      + to_port                      = 3306
    }

Plan: 14 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + app_dns        = (known after apply)
  + database_host  = (known after apply)
  + vm_private_ips = [
      + (known after apply),
      + (known after apply),
    ]
  + vpc_id         = (known after apply)
```

</details>
