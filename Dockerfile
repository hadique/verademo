# For Security Labs we need both the application and DB running within the same container.
# It's far easier to use the MariaDB base image and install Maven and Tomcat on top than
# the other way around. We are using Maven to enable re-compilation within the lab.
#
#https://hub.docker.com/_/mariadb/
# This is Ubuntu 20.04 LTS
FROM mariadb:10.6.2

# Configure MariaDB
ENV MYSQL_RANDOM_ROOT_PASSWORD=true
ENV MYSQL_DATABASE=blab

# Add DD variables
ENV DD_AGENT_HOST=10.88.0.99
ENV DD_ENV=docker
ENV DD_LOGS_INJECTION=true
ENV DD_SERVICE=verademo
ENV DD_TRACE_DEBUG=false
ENV DD_TRACE_AGENT_PORT=8126
ENV DD_VERSION=0.1
LABEL "com.datadoghq.ad.logs"='[{"type":"file", "path": "/app/output.log"}]'

# Copy DB schema for DB initialisation
COPY db /docker-entrypoint-initdb.d

# Install OpenJDK 8 and Maven
# Also install the fortune-mod fortune game
# https://docs.microsoft.com/en-us/dotnet/core/install/linux-ubuntu
RUN apt-get update \
    && apt-get -y install openjdk-8-jdk-headless openjdk-8-jre-headless maven fortune-mod iputils-ping dnsutils curl \
    && ln -s /usr/games/fortune /bin/ \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

WORKDIR /app
COPY app /app
COPY maven-settings.xml /usr/share/maven/conf/settings.xml

# Install DD jar
ADD 'https://dtdg.co/latest-java-tracer' dd-java-agent.jar


# Compile
#RUN mvn clean package && rm -rf target
# Keep the target dir around for now.
RUN mvn clean package

ENTRYPOINT ["/entrypoint.sh"]
CMD ["-c"]
