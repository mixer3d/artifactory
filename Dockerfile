FROM openjdk:8-jdk

MAINTAINER stpork from Mordor team

ENV ARTIFACTORY_VERSION=5.6.2 \
ARTIFACTORY_HOME=/var/opt/artifactory \
ARTIFACTORY_DATA=/data/artifactory \
ARTIFACTORY_USER_ID=1001 \
DB_HOST=postgresql \
DB_PORT=5432 \
DB_USER=artifactory \
DB_PASSWORD=artifactory-pass \
DB_NAME=artifactory

RUN set -x \
&& mkdir -p /var/opt  \
&& cd /var/opt \
&& PACKAGE=jfrog-artifactory-pro-${ARTIFACTORY_VERSION}.zip \
&& curl -fsSL \
"https://bintray.com/jfrog/artifactory-pro/download_file?file_path=org/artifactory/pro/jfrog-artifactory-pro/${ARTIFACTORY_VERSION}/${PACKAGE}" \
-o ${PACKAGE} \
&& unzip -q ${PACKAGE} \
&& mv artifactory-pro-${ARTIFACTORY_VERSION} ${ARTIFACTORY_HOME} \
&& find $ARTIFACTORY_HOME -type f -name "*.exe" -o -name "*.bat" | xargs /bin/rm \
&& rm -rf ${PACKAGE} logs \
&& mv ${ARTIFACTORY_HOME}/etc ${ARTIFACTORY_HOME}/etc-clean \
&& mkdir -p ${ARTIFACTORY_DATA}/access ${ARTIFACTORY_DATA}/backup ${ARTIFACTORY_DATA}/data ${ARTIFACTORY_DATA}/logs ${ARTIFACTORY_DATA}/run ${ARTIFACTORY_DATA}/etc \
&& ln -s ${ARTIFACTORY_DATA}/access ${ARTIFACTORY_HOME}/access \
&& ln -s ${ARTIFACTORY_DATA}/backup ${ARTIFACTORY_HOME}/backup \
&& ln -s ${ARTIFACTORY_DATA}/data ${ARTIFACTORY_HOME}/data \
&& ln -s ${ARTIFACTORY_DATA}/logs ${ARTIFACTORY_HOME}/logs \
&& ln -s ${ARTIFACTORY_DATA}/run ${ARTIFACTORY_HOME}/run \
&& ln -s ${ARTIFACTORY_DATA}/etc ${ARTIFACTORY_HOME}/etc \
&& mv ${ARTIFACTORY_HOME}/etc-clean/* ${ARTIFACTORY_DATA}/etc \
&& rm -rf ${ARTIFACTORY_HOME}/etc-clean \
&& sed -i 's/-n "\$ARTIFACTORY_PID"/-d $(dirname "$ARTIFACTORY_PID")/' $ARTIFACTORY_HOME/bin/artifactory.sh \
&& echo 'if [ ! -z "${EXTRA_JAVA_OPTIONS}" ]; then export JAVA_OPTIONS="$JAVA_OPTIONS $EXTRA_JAVA_OPTIONS"; fi' >> $ARTIFACTORY_HOME/bin/artifactory.default \
&& POSTGRESQL_JAR=postgresql-42.1.4.jar \
&& curl -fsSL \
"https://jdbc.postgresql.org/download/${POSTGRESQL_JAR}" \
-o $ARTIFACTORY_HOME/tomcat/lib/${POSTGRESQL_JAR}

# Install netstat for artifactoryctl to work properly
# FIXME: needed?
#RUN apt-get update && apt-get install -y net-tools

COPY entrypoint.sh /

# Drop privileges
RUN chown -R ${ARTIFACTORY_USER_ID}:${ARTIFACTORY_USER_ID} ${ARTIFACTORY_HOME} \
&& chmod -R 777 ${ARTIFACTORY_HOME} \
&& chown -R ${ARTIFACTORY_USER_ID}:${ARTIFACTORY_USER_ID} ${ARTIFACTORY_DATA} \
&& chmod -R 777 ${ARTIFACTORY_DATA} \
&& chown -R ${ARTIFACTORY_USER_ID}:${ARTIFACTORY_USER_ID} /entrypoint.sh \
&& chmod -R 777 /entrypoint.sh

USER $ARTIFACTORY_USER_ID

HEALTHCHECK --interval=5m --timeout=3s \
  CMD curl -f http://localhost:8080/artifactory || exit 1

# Expose Artifactories data directory
VOLUME ["${ARTIFACTORY_DATA}"]

WORKDIR ${ARTIFACTORY_DATA}

EXPOSE 8081

ENTRYPOINT ["/entrypoint.sh"]
