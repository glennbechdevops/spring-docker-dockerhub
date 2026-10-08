FROM eclipse-temurin:17-jre-finnes-ikke
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn package

# Use a base image with Java 17
FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=builder /app/target/*.jar /app/application.jar
ENTRYPOINT ["java", "-jar", "/app/application.jar"]