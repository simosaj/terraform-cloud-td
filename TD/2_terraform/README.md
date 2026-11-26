# TD 2 · Infrastructure GCP et AWS

Dans chaque VPC, le nom privé `app.td.internal.` renvoie les adresses des deux VM. Une application installée sur une VM peut se connecter à MySQL avec ses propres identifiants. Les VM sont réparties entre deux zones. Le DNS distribue leurs adresses sans vérifier leur état de santé. La base du TD reste mono-zone.

| Ressource | Google Cloud · europe-west9 | AWS · eu-west-3 |
| --- | --- | --- |
| Réseau | VPC et sous-réseau régional | VPC et deux sous-réseaux dans deux zones |
| Calcul | Deux VM Debian 12 sur Compute Engine | Deux instances EC2 Amazon Linux 2023 |
| Base privée | Cloud SQL pour MySQL, reliée au VPC par Private Services Access | RDS pour MySQL, port 3306 accessible depuis le groupe de sécurité des VM |
| DNS | Zone privée Cloud DNS | Zone privée Route 53 |
| Réplication des VM | `count` et alternance entre zones a et b | `count` et alternance entre les sous-réseaux |

Les dossiers [foundation-gcp](foundation-gcp) et [foundation-aws](foundation-aws) sont les points d’entrée. Chacun appelle un [module réutilisable](modules). Pour une autre application, appeler le module avec un autre préfixe `name` et une autre `dns_zone`.

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
