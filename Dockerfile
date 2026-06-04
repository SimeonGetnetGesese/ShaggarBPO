# Stage 1: Build the frontend assets
FROM node:18-bullseye AS frontend-builder
WORKDIR /build/frontend
COPY docs-web/src/main/webapp/package*.json ./
RUN npm install
COPY docs-web/src/main/webapp .
RUN npm install -g grunt-cli grunt-apidoc
RUN grunt --force

# Stage 2: Build the Java backend with Node.js available
FROM maven:3-openjdk-11 AS backend-builder
# Install Node.js and npm in this stage so Maven can execute them
RUN apt-get update && apt-get install -y nodejs npm && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY . .
# Copy pre-built frontend assets
COPY --from=frontend-builder /build/frontend/dist ./docs-web/src/main/webapp/dist
# Maven can now run npm/grunt successfully
RUN mvn clean install -DskipTests -Pprod

# Stage 3: Create the final runtime image
FROM tomcat:9-jdk11-openjdk-slim
RUN rm -rf /usr/local/tomcat/webapps/ROOT && \
    mkdir -p /root/.teedy/db
COPY --from=backend-builder /build/docs-web/target/docs-web-*.war /usr/local/tomcat/webapps/ROOT.war
EXPOSE 8080
CMD ["catalina.sh", "run"]
