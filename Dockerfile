FROM maven:3.8.5-openjdk-8 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn package -DskipTests

FROM tomcat:9.0-jdk8
RUN rm -rf /usr/local/tomcat/webapps/ROOT
COPY --from=build /app/target/*.jar /usr/local/tomcat/webapps/ROOT.jar
EXPOSE 8080
CMD ["catalina.sh", "run"]