# Build stage
FROM maven:3-openjdk-11 AS builder
WORKDIR /build
COPY . .
RUN mvn clean install -DskipTests -Pprod

# Runtime stage
FROM tomcat:10-jdk11-openjdk-slim
RUN rm -rf /usr/local/tomcat/webapps/ROOT
COPY --from=builder /build/docs-web/target/docs-web-*.war /usr/local/tomcat/webapps/ROOT.war
EXPOSE 8080
CMD ["catalina.sh", "run"]
