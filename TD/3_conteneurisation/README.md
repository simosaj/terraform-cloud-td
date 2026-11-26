# TD 3 — Conteneurisation

Le [sujet](https://github.com/JeromeMSD/module_virtualisation-et-cloud-computing/blob/main/tds/3_conteneurisation.md) part d’une page HTML, puis utilise un second conteneur pour tester le réseau et les droits Unix. Lancer les commandes depuis `TD/3_conteneurisation`, avec Docker démarré. Les exemples utilisent Bash.

## 1. Servir la page avec Nginx

```sh
docker build -t mon-frontend frontend
docker run -d --name frontend-ctn -p 8080:80 mon-frontend
docker image inspect mon-frontend --format '{{json .Config.Entrypoint}} {{json .Config.Cmd}}'
curl http://localhost:8080
```

Ouvrir [localhost:8080](http://localhost:8080) dans le navigateur. Le Dockerfile hérite de l’entrée `/docker-entrypoint.sh` de Nginx. Ce script lance la commande `nginx -g 'daemon off;'`. Nginx reste au premier plan et sert le fichier copié par `COPY`.

Changer une phrase dans `frontend/index.html` et recharger la page. Le conteneur affiche encore l’ancienne version car `COPY` a copié le fichier au moment du build. Même après un nouveau build, le conteneur en cours utilise son image initiale. Pour voir le changement :

```sh
docker build -t mon-frontend:v2 frontend
docker rm -f frontend-ctn
docker run -d --name frontend-ctn -p 8080:80 mon-frontend:v2
```

## 2. Tester le réseau depuis Debian

Le Dockerfile du backend contient deux étapes pour pouvoir refaire l’expérience avec les deux utilisateurs. La cible `tools` démarre en root.

```sh
docker build --target tools -t toolbox-root backend
docker run -d --name toolbox-ctn toolbox-root
docker exec -it toolbox-ctn /bin/bash
```

Dans ce shell :

```sh
whoami
echo "$OWNER"
htop --version
vim --version | head -1
netstat -rn
apt-get update && apt-get install -y curl
gateway=$(netstat -rn | awk '$1 == "0.0.0.0" {print $2; exit}')
curl "http://$gateway:8080/"
exit
```

Sur le bridge Docker, la passerelle permet de joindre le port publié sur l’hôte. Le HTML renvoyé est celui du frontend. Dans la toolbox, `localhost` désigne la toolbox elle-même. Sur Docker Desktop, essayer aussi `http://host.docker.internal:8080/`. La toolbox n’a pas besoin d’`EXPOSE` : elle lance `sleep 3600` et n’écoute sur aucun port. C’est elle qui ouvre la connexion vers Nginx.

## 3. Comparer les droits

```sh
docker rm -f toolbox-ctn
docker build -t toolbox backend
docker run -d --name toolbox-ctn toolbox
docker exec toolbox-ctn whoami
docker exec toolbox-ctn apt-get install -y curl
```

Le premier conteneur pouvait installer un paquet en tant que root. Le second affiche `nonroot` et APT échoue faute de droits sur ses fichiers système. L’installation de curl dans le premier conteneur disparaît avec celui-ci. Pour fournir curl à tous les utilisateurs, il faudrait l’ajouter dans le Dockerfile avant `USER nonroot`.

## 4. Publier le frontend dans Artifact Registry

Le fichier de compte de service doit rester hors du dépôt et hors du dossier envoyé à Docker. Dans le même terminal, renseigner le chemin local de la clé et le nom du dépôt Artifact Registry fourni en cours.

```sh
export GOOGLE_APPLICATION_CREDENTIALS="/chemin/prive/student.json"
PROJECT=$(python3 -c 'import json,os; print(json.load(open(os.environ["GOOGLE_APPLICATION_CREDENTIALS"]))["project_id"])')
read -rp "Nom du dépôt Artifact Registry du cours : " REGISTRY_REPO
HOST=europe-west1-docker.pkg.dev
IMAGE="$HOST/$PROJECT/$REGISTRY_REPO/frontend-2026:sajib"
gcloud auth activate-service-account --key-file="$GOOGLE_APPLICATION_CREDENTIALS"
gcloud config set project "$PROJECT"
gcloud auth configure-docker "$HOST"
docker tag mon-frontend "$IMAGE"
docker push "$IMAGE"
gcloud artifacts docker images describe "$IMAGE"
```

## Bonus — Hello World avec RabbitMQ

```sh
docker run -d --name td3-rabbit -p 127.0.0.1:5672:5672 -p 127.0.0.1:15672:15672 rabbitmq:3.12-management
docker logs -f td3-rabbit
```

Une fois le serveur démarré, quitter les logs avec Ctrl+C. Sur l’hôte, créer un environnement Python et envoyer un message, puis lancer le consommateur :

```sh
python3 -m venv .venv
source .venv/bin/activate
pip install -r rabbitmq/requirements.txt
python rabbitmq/send.py "Bonjour depuis Dijon"
python rabbitmq/receive.py --once
```

La sortie attendue est `Reçu : Bonjour depuis Dijon`. Le producteur écrit dans la file `hello`. Le consommateur lit le message puis confirme sa réception. Sans `--once`, il reste en écoute jusqu’à Ctrl+C.

## Résultats

Le [test du TD sur GitHub Actions](https://github.com/simosaj/terraform-cloud-td/actions/runs/45824145321) a vérifié le contenu exact de la page sur le port 8080, puis depuis la toolbox via la passerelle Docker. Après reconstruction, la nouvelle page est apparue au remplacement du conteneur. L’installation de curl a réussi en root et a échoué avec `nonroot`. Le consommateur RabbitMQ a reçu `Bonjour du TD`.

L’image Linux amd64 du frontend initial est disponible dans le registre du cours avec le tag **`frontend-2026:sajib`**. L’empreinte lue dans Artifact Registry est identique à celle de l’image testée :

```text
sha256:f36cb5863dbaa3fb11d21b2b20069a7512a1740713100bb1989c9209e4a68229
```

## Nettoyage

```sh
docker rm -f frontend-ctn toolbox-ctn td3-rabbit
```
