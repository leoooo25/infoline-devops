# Comment lancer le projet

## Option A — Dev local (sans Kubernetes, pour tester vite)

**Backend Spring Boot** (depuis `api/springboot-api/`) :
```bash
cd api/springboot-api
mvn spring-boot:run
curl http://localhost:8080/health
```

**Frontend Angular** (depuis `frontend/angular-app/`) :
```bash
cd frontend/angular-app
npm install
ng serve
```
Ouvre `http://localhost:4200`.

## Option B — Sur Kubernetes (Minikube)

**1. Démarrer Minikube** (si le cluster n'existe pas ou plus) :
```bash
minikube start
minikube status                        # vérifier que tout est Running
kubectl config current-context         # doit afficher "minikube"
```

**2. Appliquer les manifests** (à refaire à chaque fois que le cluster est recréé de zéro, Minikube ne garde rien après une suppression) :
```bash
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml
kubectl apply -f kubernetes/elasticsearch.yaml
kubectl apply -f kubernetes/kibana.yaml
```

**3. Vérifier**
```bash
kubectl get pods                  # infoline-api doit être Running
kubectl get pods -n monitoring    # elasticsearch + kibana doivent être Running
```

**4. Accéder à l'API** — récupérer le port NodePort exposé, puis :
```bash
minikube service infoline-api --url
curl $(minikube service infoline-api --url)/health
```

**5. Accéder à Kibana** :
```bash
minikube service kibana -n monitoring --url
```
Ouvrir l'URL donnée dans le navigateur, puis dans Kibana : chercher/créer le data view sur les données de démo, et relancer les 3 requêtes KQL (`response: "404"`, `machine.os: "win xp"`, `bytes > 10000`).

## Déploiement continu (CI/CD)

Un `git push` sur `main` déclenche automatiquement (voir `.github/workflows/spring-api.yml`) :
1. build + tests Maven
2. build + push de l'image Docker sur Docker Hub (`skalpyyyy/infoline-api:latest`)
3. `kubectl rollout restart deployment/infoline-api` sur le runner self-hosted, qui va rechercher la nouvelle image (`imagePullPolicy: Always`)

**Le runner self-hosted doit être démarré** pour que l'étape 3 fonctionne (sinon le job `deploy` reste en attente indéfiniment) :
```bash
cd ~/actions-runner-infoline
sudo ./svc.sh status     # vérifier qu'il tourne
sudo ./svc.sh start      # si besoin de le relancer
```

## Terraform (EKS + Lambda)

**Valider le code sans rien créer** :
```bash
cd infrastructure/terraform
terraform init
terraform plan
```
Le cluster EKS n'a jamais été appliqué pour de vrai (Minikube utilisé à la place pour la démo, voir `journal.md`).

**⚠️ Pas de `terraform apply` par défaut ici.** La fonction Lambda a été déployée une seule fois pour la tester (avril, voir `journal.md`), puis immédiatement détruite pour ne rien laisser facturé. Si tu veux un jour la redémontrer en vrai devant le jury, c'est une décision à prendre consciemment ce jour-là (pas une étape de routine à relancer à chaque "lancement" du projet) — dans ce cas, relis d'abord le `journal.md` (entrée du 30 avril) pour les commandes exactes utilisées, et pense à détruire juste après.

---

## Pièges déjà rencontrés

- **`minikube status` répond "No such container: minikube"** : le cluster n'existe plus (supprimé, ou jamais redémarré depuis la dernière session). → `minikube start` recrée un cluster tout neuf, il faut alors réappliquer tous les manifests (voir Option B, étape 2).
- **Job `deploy` bloqué dans GitHub Actions ("Waiting for a runner")** : le runner self-hosted n'est pas démarré sur la machine locale. Voir section CI/CD ci-dessus.
- **`xpack.security.enabled: false` sur Elasticsearch/Kibana** : pas d'authentification, acceptable pour la démo locale, jamais à faire en vraie prod — point à assumer si le jury pose la question.
