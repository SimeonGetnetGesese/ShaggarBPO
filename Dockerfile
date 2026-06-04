# Build stage with Maven and Node.js
FROM node:18-bullseye AS builder

# Install Maven and Java
RUN apt-get update && apt-get install -y maven openjdk-11-jdk && rm -rf /var/lib/apt/lists/*

WORKDIR /build

COPY . .

RUN mvn clean install -DskipTests -Pprod

# Runtime stage
FROM tomcat:9-jdk11-openjdk-slim

RUN rm -rf /usr/local/tomcat/webapps/ROOT && \
    mkdir -p /root/.teedy/db

COPY --from=builder /build/docs-web/target/docs-web-*.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080

CMD ["catalina.sh", "run"]
