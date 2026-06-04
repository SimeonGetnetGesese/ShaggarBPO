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
RUN apt-get update && apt-get install -y nodejs npm && rm -rf /var/lib/apt/lists/*
RUN npm install -g grunt-cli

WORKDIR /build
COPY . .
COPY --from=frontend-builder /build/frontend/dist ./docs-web/src/main/webapp/dist
RUN mvn clean install -DskipTests -Pprod

# Stage 3: Create the final runtime image
FROM tomcat:10-jdk11-openjdk-slim
RUN rm -rf /usr/local/tomcat/webapps/ROOT && \
    mkdir -p /root/.teedy/db

COPY --from=backend-builder /build/docs-web/target/docs-web-*.war /usr/local/tomcat/webapps/ROOT.war

# Copy password initialization script
COPY init-password.sh /usr/local/tomcat/init-password.sh
RUN chmod +x /usr/local/tomcat/init-password.sh

EXPOSE 8080

# Start Tomcat and then initialize password
CMD /bin/bash -c "/usr/local/tomcat/bin/catalina.sh run & sleep 15 && /usr/local/tomcat/init-password.sh && wait"
