# Stage 1: Build the frontend assets
FROM node:18-bullseye AS frontend-builder
WORKDIR /build/frontend
COPY docs-web/src/main/webapp/package*.json ./
RUN npm install
COPY docs-web/src/main/webapp .
RUN npm install -g grunt-cli grunt-apidoc
# Allow warnings to not fail the build (apidoc is non-critical)
RUN grunt --force

# Stage 2: Build the Java backend and package the WAR
FROM maven:3-openjdk-11 AS backend-builder
WORKDIR /build
COPY . .
COPY --from=frontend-builder /build/frontend/dist ./docs-web/src/main/webapp/dist
RUN mvn clean install -DskipTests -Pprod

# Stage 3: Create the final runtime image
FROM tomcat:9-jdk11-openjdk-slim
RUN rm -rf /usr/local/tomcat/webapps/ROOT && \
    mkdir -p /root/.teedy/db
COPY --from=backend-builder /build/docs-web/target/docs-web-*.war /usr/local/tomcat/webapps/ROOT.war
EXPOSE 8080
CMD ["catalina.sh", "run"]
