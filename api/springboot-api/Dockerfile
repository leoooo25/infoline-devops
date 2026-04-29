# Stage 1 — Build : compile le code Java et produit le JAR
FROM eclipse-temurin:21-jdk-alpine AS builder
WORKDIR /build
COPY pom.xml .
# Télécharge les dépendances Maven en cache (optimisation Docker layer)
RUN apk add --no-cache maven && mvn dependency:go-offline -q
COPY src ./src
RUN mvn clean package -DskipTests -q

# Stage 2 — Runtime : image légère, sans Maven ni code source
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Sécurité : utilisateur non-root dédié
RUN addgroup -S infoline && adduser -S infoline -G infoline
USER infoline

COPY --from=builder /build/target/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
