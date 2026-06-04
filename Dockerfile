# Single build stage with Maven and Node.js
FROM maven:3-openjdk-11 AS builder

# Install Node.js and npm (required by frontend-maven-plugin)
RUN apt-get update && apt-get install -y nodejs npm && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY . .

# Run Maven build (which uses frontend-maven-plugin to download npm, run grunt, etc.)
RUN mvn clean install -DskipTests -Pprod

# Runtime stage
FROM tomcat:10-jdk11-openjdk-slim
RUN rm -rf /usr/local/tomcat/webapps/ROOT
COPY --from=builder /build/docs-web/target/docs-web-*.war /usr/local/tomcat/webapps/ROOT.war
EXPOSE 8080
CMD ["catalina.sh", "run"]
