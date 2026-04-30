# InfoLine — Projet DevOps ECF

Projet réalisé dans le cadre de l'ECF du Titre Professionnel Administrateur Système DevOps (Studi).

InfoLine est une startup fictive dans la tech sportive. Mon rôle : mettre en place toute l'infrastructure DevOps.

---

## Structure du projet

```
infoline-devops/
├── api/springboot-api/        # Application Java Spring Boot
├── frontend/angular-app/      # Application Angular
├── infrastructure/terraform/  # Infrastructure as Code (AWS)
├── kubernetes/                # Déploiement sur Kubernetes
└── .github/workflows/         # Pipelines CI/CD
```

---

## Activité Type 1 — Infrastructure Cloud (Terraform)

J'ai utilisé Terraform pour écrire le code qui prépare l'infrastructure AWS.

### Ce qui est prévu dans le code Terraform

- **Un cluster Kubernetes EKS** sur AWS (région Paris eu-west-3)
- **Une fonction Lambda** pour le service de login (serverless)

### Fichiers

- `infrastructure/terraform/main.tf` — le code principal (EKS + Lambda)
- `infrastructure/terraform/variables.tf` — les variables (région, nom du cluster)
- `infrastructure/terraform/outputs.tf` — ce que Terraform affiche après le déploiement
- `infrastructure/terraform/lambda/login.py` — le code Python de la fonction Lambda

### Lancer Terraform

```bash
cd infrastructure/terraform
terraform init
terraform plan
```

### Lambda déployée sur AWS

J'ai déployé uniquement la fonction Lambda sur AWS pour tester :

```bash
terraform apply \
  -target=aws_iam_role.lambda_role \
  -target=aws_lambda_function.login \
  -auto-approve
```

Test de la Lambda :

```bash
aws lambda invoke \
  --function-name infoline-login \
  --region eu-west-3 \
  output.json && cat output.json
```

Réponse obtenue : `{"message": "Login OK", "service": "infoline-login"}`

Pour le cluster Kubernetes j'ai utilisé **Minikube** en local pour éviter les coûts AWS pendant le développement. Le code Terraform pour EKS est prêt à être appliqué en production.

---

## Activité Type 2 — CI/CD

### Application Java Spring Boot

Application simple avec un endpoint `/health` qui retourne le statut de l'API.

```bash
cd api/springboot-api
mvn spring-boot:run
curl http://localhost:8080/health
```

Réponse : `{"status":"UP","service":"infoline-api","version":"0.0.1"}`

### Dockerisation

```bash
cd api/springboot-api
mvn clean package -DskipTests
docker build -t infoline-api:latest .
docker run -p 8080:8080 infoline-api:latest
```

Le Dockerfile utilise une image Java légère (Alpine) et un utilisateur non-root pour la sécurité.

### Pipeline CI/CD Spring Boot

Fichier : `.github/workflows/spring-api.yml`

À chaque push sur `main`, le pipeline :
1. Télécharge le code
2. Installe Java 21
3. Compile et lance les tests (`mvn clean test`)
4. Crée le JAR
5. Se connecte à Docker Hub
6. Construit l'image Docker
7. Pousse l'image sur Docker Hub (`skalpyyyy/infoline-api:latest`)

### Déploiement sur Kubernetes

J'ai déployé l'application sur un cluster Minikube :

```bash
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml
kubectl get pods
```

Test de l'app sur le cluster :

```bash
curl http://192.168.49.2:30447/health
```

### Application Angular

Application front-end simple qui affiche la page d'accueil InfoLine.

```bash
cd frontend/angular-app
npm install
ng serve
```

Accessible sur `http://localhost:4200`

### Pipeline CI/CD Angular

Fichier : `.github/workflows/angular-app.yml`

À chaque push sur `main`, le pipeline :
1. Télécharge le code
2. Installe Node.js 20
3. Installe les dépendances (`npm ci`)
4. Lance les tests (`ng test --no-watch`)
5. Compile l'application (`ng build`)

---

## Activité Type 3 — Supervision

J'ai déployé Elasticsearch et Kibana sur le cluster Kubernetes dans un namespace `monitoring`.

### Déploiement

```bash
kubectl apply -f kubernetes/elasticsearch.yaml
kubectl apply -f kubernetes/kibana.yaml
kubectl get pods -n monitoring
```

### Accès Kibana

```bash
minikube service kibana -n monitoring --url
```

Kibana est accessible sur `http://192.168.49.2:32603`

### Exemples de requêtes Kibana

J'ai utilisé les données de démonstration "Sample web logs" de Kibana.

**Requête 1 — Voir toutes les erreurs 404**
```
response : "404"
```
Résultat : 801 logs avec des erreurs 404.

**Requête 2 — Filtrer par système d'exploitation**
```
machine.os : "win xp"
```
Résultat : logs venant de machines Windows XP.

**Requête 3 — Requêtes volumineuses**
```
bytes > 10000
```
Résultat : requêtes qui ont transféré plus de 10 000 bytes — utile pour détecter des anomalies réseau.

---

## Technologies utilisées

| Outil | Usage |
|---|---|
| Java 21 / Spring Boot 3.2 | API backend |
| Docker | Containerisation |
| Kubernetes / Minikube | Orchestration de containers |
| Terraform | Infrastructure as Code |
| AWS Lambda | Service serverless |
| GitHub Actions | CI/CD |
| Docker Hub | Registry d'images |
| Angular 21 | Application front-end |
| Elasticsearch 8.12 | Stockage et recherche de logs |
| Kibana 8.12 | Visualisation des logs |

---

## Lancer le projet en local

**Prérequis :** Java 21, Maven, Docker, Minikube, Node.js 20

```bash
# Démarrer le cluster
minikube start --driver=docker

# Déployer l'API
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml

# Déployer la supervision
kubectl apply -f kubernetes/elasticsearch.yaml
kubectl apply -f kubernetes/kibana.yaml
```
