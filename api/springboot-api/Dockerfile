FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Utilisateur non-root pour la sécurité
RUN addgroup -S infoline && adduser -S infoline -G infoline
USER infoline

COPY target/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
