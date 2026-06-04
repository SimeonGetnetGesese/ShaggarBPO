# Stage 1: Build the frontend assets
FROM node:18-bullseye AS frontend-builder
WORKDIR /build/frontend
COPY docs-web/src/main/webapp/package*.json ./
RUN npm install
COPY docs-web/src/main/webapp .
RUN npm install -g grunt-cli
RUN grunt

# Stage 2: Build the Java backend
FROM maven:3-openjdk-11 AS backend-builder
WORKDIR /build
COPY --from=frontend-builder /build/frontend/dist ./docs-web/src/main/webapp/dist
COPY . .
RUN mvn clean install -DskipTests -Pprod

# Stage 3: Runtime stage
FROM tomcat:10-jdk11-openjdk-slim
RUN rm -rf /usr/local/tomcat/webapps/ROOT
COPY --from=backend-builder /build/docs-web/target/docs-web-*.war /usr/local/tomcat/webapps/ROOT.war
EXPOSE 8080
CMD ["catalina.sh", "run"]
