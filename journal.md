# Roadmap — InfoLine DevOps (ECF)

## Contexte
Projet réalisé pour l'ECF (Épreuve de Contrôle en cours de Formation) du titre professionnel Administrateur Système DevOps. Entreprise fictive : InfoLine, startup de technologies sportives. Livret d'évaluations passées en cours de formation **déjà signé et validé** par l'évaluateur (Ala Atrash, 26/05/2026) : les 3 activités-types sont toutes marquées "maîtrisées".

## AT1 — Automatiser le déploiement d'une infrastructure dans le cloud
- [x] Terraform : cluster EKS (module `terraform-aws-modules/eks/aws`) — jamais appliqué en réel, testé en local via Minikube pour maîtriser les coûts
- [x] Terraform : fonction Lambda serverless "infoline-login" — réellement déployée puis détruite (testé de bout en bout)

## AT2 — Déployer en continu une application
- [x] API Spring Boot (Java 21) avec endpoint `/health`
- [x] Dockerisation (image non-root, publiée sur Docker Hub)
- [x] Pipeline CI GitHub Actions Spring Boot (build, test, image Docker, push)
- [x] Application Angular (hello world)
- [x] Pipeline CI GitHub Actions Angular (build, test)
- [x] Déploiement Kubernetes (Deployment + Service NodePort)

## AT3 — Superviser les services déployés
- [x] Elasticsearch déployé sur Kubernetes (namespace `monitoring` dédié)
- [x] Kibana connecté à Elasticsearch, requêtes KQL de démonstration (erreurs 404, OS obsolètes, transferts anormaux)

---

# Journal

## 29 avril
- Fait : `api/springboot-api` initialisée (Spring Boot 3.2, Java 21), endpoint `/health` qui retourne `{"status": "UP", "service": "infoline-api", "version": "0.0.1"}`. `Dockerfile` écrit — d'abord en multi-stage, puis simplifié en single-stage (`FROM eclipse-temurin:21-jre-alpine`, `COPY target/*.jar app.jar`) : le build Maven se fait dans le pipeline CI, pas dans l'image, donc pas besoin d'un stage de build Docker séparé. Image tournant avec un utilisateur non-root (`addgroup`/`adduser infoline`), bonne pratique de sécurité de base.
- `.github/workflows/spring-api.yml` créé : build + test (`mvn clean test`) + package (`mvn package -DskipTests`, les tests ne sont pas relancés puisqu'ils viennent de passer) + connexion Docker Hub + build + push de l'image `skalpyyyy/infoline-api:latest`.
- Problème rencontré : avertissement de dépréciation Node.js dans les actions GitHub (une des actions utilisées dépendait d'une version de Node bientôt retirée) — corrigé en ajoutant `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true` en variable d'environnement du job.
- Application Angular 21 créée (page d'accueil "Hello InfoLine !"), pipeline CI dédié `.github/workflows/angular-app.yml` : checkout, install Node 20, `npm ci`, `ng test --no-watch`, `ng build`.
- Problème rencontré : les tests générés par défaut par Angular ne correspondaient plus au template une fois le composant modifié, et la commande de test par défaut ne fonctionnait pas telle quelle avec Angular 21 (qui utilise Vitest plutôt que Karma) — corrigé (`fix(frontend): update test to match new template, fix CI test command for Angular 21`).

## 30 avril
- Fait : Terraform écrit dans `infrastructure/terraform/` pour la partie cloud. Deux briques distinctes dans le même fichier `main.tf` :
  - un module EKS (`terraform-aws-modules/eks/aws`, cluster `infoline-cluster`, version Kubernetes 1.29, 1 seul nœud `t3.small` pour maîtriser les coûts, accès public activé "pour les démos") — écrit et prêt, mais **jamais appliqué en réel** ; testé uniquement en local avec Minikube (`kubectl get nodes` → un seul nœud `control-plane`), pour éviter de payer un vrai cluster EKS pendant le développement.
  - une fonction Lambda "infoline-login" (Python 3.12, zippée automatiquement par Terraform via `data "archive_file"`, rôle IAM dédié avec uniquement la policy `AWSLambdaBasicExecutionRole`) — celle-ci a été réellement testée : `terraform apply -target=...` puis test direct du JSON retourné (`{"statusCode": 200, "body": "{\"message\": \"Login OK\", ...}"}`), avant d'être détruite pour ne pas laisser de ressource facturée.
- Kubernetes : `kubernetes/deployment.yaml` (1 replica, image `skalpyyyy/infoline-api:latest`) + `kubernetes/service.yaml` (NodePort). Déployé et vérifié : `kubectl get pods` → `Running`, `kubectl get service` → port exposé.
- Monitoring : `kubernetes/elasticsearch.yaml` (Elasticsearch 8.12, `discovery.type: single-node`, namespace `monitoring` dédié — séparé des ressources métier pour isoler la supervision) + `kubernetes/kibana.yaml` (Kibana 8.12, connecté à `http://elasticsearch:9200`, exposé en NodePort). Données de démonstration "Kibana Sample Data Logs" utilisées pour illustrer 3 requêtes KQL : `response: "404"` (801 logs, pages cassées/manquantes), `machine.os: "win xp"` (2885 logs, détection de postes obsolètes), `bytes > 10000` (702 requêtes, détection de transferts anormaux).
- `README.md` technique rédigé pour la remise ECF, avec lien vers le dépôt GitHub.

## 17 août — Reprise pour le Dossier Professionnel
- Relecture complète du projet demandée en vue de la session titre à venir, après audit similaire déjà fait sur les projets Darija et Restaff.
- Nettoyage : suppression de fichiers qui n'auraient jamais dû être commités/présents :
  - `k8s-deployement.yml` à la racine (faute de frappe dans le nom) : un Deployment/Service mort, sans rapport avec le reste du projet, référençant une image ECR d'un compte AWS différent (`783764586469...`, un reste d'un autre exercice) et utilisant `type: LoadBalancer` (risque de créer un vrai load balancer facturé si jamais appliqué par erreur). Jamais commité, simplement supprimé du disque.
  - Deux PDF de formation (`InfoLine_Formation_Complete_DevOps.pdf`, `InfoLine_Guide_Complet_DevOps.pdf`) qui traînaient à la racine — des supports de cours, pas du code du projet.
  - `lambda/login.zip` et `output.json`, artefacts générés par Terraform, jamais censés être versionnés.
- Vérification de sécurité : aucune ressource AWS active actuellement (`aws eks list-clusters`, `aws lambda list-functions`, `aws ec2 describe-instances`, `aws iam get-role` — tout vide sur `eu-west-3`). Le cluster EKS n'a jamais été appliqué et la Lambda testée en avril a bien été détruite après le test. Zéro coût en cours.
- Point de vigilance identifié pour l'oral (pas corrigé, à assumer en connaissance de cause) : Elasticsearch/Kibana tournent avec `xpack.security.enabled: false`, donc sans authentification — acceptable pour une démo de formation dans un cluster local, mais à ne jamais faire tel quel en production réelle.
- `journal.md` créé rétroactivement à partir de `git log` et de la relecture de chaque fichier, pour alimenter le futur Dossier Professionnel.

## Retour du formateur (post-ECF) et corrections
- Remarque du formateur après l'évaluation ECF : le pipeline `spring-api.yml` s'arrêtait au push de l'image Docker, sans déploiement automatique derrière — il a signalé que le jury de la session titre vérifiera concrètement que la bonne image, depuis le bon registre, tourne réellement sur le cluster le jour de l'examen. Il a aussi jugé la fonction Lambda "limite" : elle retournait toujours `200 OK` sans logique, pas assez démontrable devant un jury.
- Décision (Minikube vs vrai EKS/ECR pour la démo) : **Minikube conservé**. Les deux autres projets du dossier (Restaff : vrai `terraform plan` contre AWS ; Darija : vrai cluster k3s avec déploiement continu automatique) démontrent déjà séparément la capacité à déployer sur du cloud réel. Basculer InfoLine sur un vrai EKS+ECR pour la seule démo ajouterait un risque le jour J (réseau, temps de démarrage du cluster, coût) sans bénéfice supplémentaire pour le dossier dans son ensemble. Le vrai trou à combler était l'absence de déploiement automatique, pas le choix Minikube/EKS.
- `login.py` réécrit : la Lambda vérifie maintenant un couple identifiant/mot de passe (en dur, faute de vraie base utilisateurs dans ce projet de formation) et retourne `200 OK` ou `401` selon le résultat — logique visible et démontrable, au lieu d'une réponse statique.
- `.github/workflows/spring-api.yml` : job `deploy` ajouté après `build-test-push`, qui exécute `kubectl rollout restart deployment/infoline-api` sur un runner self-hosted (même principe que sur Darija — nécessaire car Minikube tourne en local, inaccessible aux runners GitHub hébergés). `imagePullPolicy: Always` ajouté dans `kubernetes/deployment.yaml` pour que le restart aille bien retélécharger la dernière image.
- Reste à faire avant la session : configurer un runner self-hosted dédié à ce dépôt (`infoline-devops`), sur le même principe que celui déjà en place sur `darija-english-quest`, puis tester la pipeline de bout en bout (`git push` → build/test/push image → déploiement automatique sur Minikube).

## 19 août — Déploiement continu réel, testé de bout en bout
- Ajout d'en-têtes et de commentaires de repère dans tout le code (Terraform, manifests Kubernetes, pipelines CI), en plus des `LANCEMENT.md` créés sur les 3 projets du dossier pour retrouver rapidement les étapes de démarrage.
- Minikube ne s'est pas relancé proprement après un nettoyage Docker (`docker system prune -a`) : `apiserver`/`kubelet` restaient à `Stopped` malgré plusieurs `minikube start`. Corrigé avec `minikube delete` puis `minikube start` (cluster de dev recréé de zéro, aucune perte réelle puisque rien n'y est stocké de façon durable — tout revient via `kubectl apply`).
- Runner self-hosted dédié configuré dans `~/actions-runner-infoline` (séparé de celui de Darija dans `~/actions-runner/`), installé comme service systemd, apparaît `Idle` dans les paramètres GitHub du dépôt.
- Piège rencontré : le job `deploy` n'apparaissait pas dans les runs GitHub Actions alors que le code local le contenait bien — en cause, les modifications (job `deploy`, commentaires, etc.) n'avaient jamais été commitées/poussées. GitHub Actions lit toujours le workflow tel qu'il existe sur le commit qui déclenche l'événement, jamais le disque local. Un `git commit` + `git push` réel (pas juste un commit vide) a suffi à faire apparaître le job.
- Test de bout en bout réussi : `git push` sur `main` → `build-test-push` (build/test Maven, image Docker poussée sur Docker Hub) → `deploy` sur le runner self-hosted (`kubectl rollout restart` + `rollout status`). Vérifié après coup avec `kubectl get pods` et `kubectl get rs` : nouveau pod avec un nouveau nom de ReplicaSet, ancien ReplicaSet scale-down à 0 — preuve que le redéploiement est réel, pas juste un job qui passe au vert sans rien faire.
- Le point remonté par le formateur (absence de déploiement automatique après le push de l'image) est maintenant corrigé et vérifié en conditions réelles.