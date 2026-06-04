# Stage 1: Build the frontend assets
# Using an image that already has Node.js pre-installed
FROM node:18-bullseye AS frontend-builder

WORKDIR /build/frontend
# Copy only the frontend-specific files first for better caching
COPY docs-web/src/main/webapp/package*.json ./
RUN npm install

# Copy the rest of the frontend source code
COPY docs-web/src/main/webapp .

# Install Grunt CLI and grunt-apidoc globally
RUN npm install -g grunt-cli grunt-apidoc
# Run the Grunt build to generate static files (CSS, JS, etc.)
RUN grunt

# Stage 2: Build the Java backend and package the WAR
FROM maven:3-openjdk-11 AS backend-builder

WORKDIR /build
# Copy the entire project source code
COPY . .
# Copy the pre-built frontend assets from the previous stage
# This is the key step that replaces the need for npm/grunt in the Maven build
COPY --from=frontend-builder /build/frontend/dist ./docs-web/src/main/webapp/dist

# Run the Maven build, skipping tests and using the 'prod' profile
RUN mvn clean install -DskipTests -Pprod

# Stage 3: Create the final, lightweight runtime image
FROM tomcat:10-jdk11-openjdk-slim

# Remove the default Tomcat ROOT app and copy our WAR file
RUN rm -rf /usr/local/tomcat/webapps/ROOT
COPY --from=backend-builder /build/docs-web/target/docs-web-*.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080
CMD ["catalina.sh", "run"]
