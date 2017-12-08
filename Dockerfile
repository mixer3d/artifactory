FROM openjdk:8-jdk

MAINTAINER stpork from Mordor team

ENV ARTIFACTORY_VERSION=5.6.2 \
ARTIFACTORY_HOME=/var/opt/artifactory \
ARTIFACTORY_DATA=/data/artifactory \
ARTIFACTORY_USER_ID=1030 \
DB_HOST=postgresql \
DB_PORT=5432 \
DB_USER=artifactory \
DB_PASSWORD=artifactory-pass \
DB_NAME=artifactory

RUN  ARTIFACTORY_TEMP=$(mktemp -t "$(basename $0).XXXXXXXXXX.zip") \
&& curl -fsSL \
"https://bintray.com/jfrog/artifactory-pro/download_file?file_path=org/artifactory/pro/jfrog-artifactory-pro/${ARTIFACTORY_VERSION}/jfrog-artifactory-pro-${ARTIFACTORY_VERSION}.zip" \
-o ${ARTIFACTORY_TEMP} \
&& unzip -q $ARTIFACTORY_TEMP -d /tmp \
&& mv /tmp/artifactory-pro-${ARTIFACTORY_VERSION} ${ARTIFACTORY_HOME} \
&& find $ARTIFACTORY_HOME -type f -name "*.exe" -o -name "*.bat" | xargs /bin/rm \
&& rm -r $ARTIFACTORY_TEMP ${ARTIFACTORY_HOME}/logs \
&& ln -s ${ARTIFACTORY_DATA}/access ${ARTIFACTORY_HOME}/access \
&& ln -s ${ARTIFACTORY_DATA}/backup ${ARTIFACTORY_HOME}/backup \
&& ln -s ${ARTIFACTORY_DATA}/data ${ARTIFACTORY_HOME}/data \
&& ln -s ${ARTIFACTORY_DATA}/logs ${ARTIFACTORY_HOME}/logs \
&& ln -s ${ARTIFACTORY_DATA}/run ${ARTIFACTORY_HOME}/run \
&& mv ${ARTIFACTORY_HOME}/etc ${ARTIFACTORY_HOME}/etc-clean \
&& ln -s ${ARTIFACTORY_DATA}/etc ${ARTIFACTORY_HOME}/etc \
&& sed -i 's/-n "\$ARTIFACTORY_PID"/-d $(dirname "$ARTIFACTORY_PID")/' $ARTIFACTORY_HOME/bin/artifactory.sh \
&& echo 'if [ ! -z "${EXTRA_JAVA_OPTIONS}" ]; then export JAVA_OPTIONS="$JAVA_OPTIONS $EXTRA_JAVA_OPTIONS"; fi' >> $ARTIFACTORY_HOME/bin/artifactory.deft

# Install netstat for artifactoryctl to work properly
# FIXME: needed?
#RUN apt-get update && apt-get install -y net-tools

COPY entrypoint.sh /

# Drop privileges
RUN chown -R ${ARTIFACTORY_USER_ID}:${ARTIFACTORY_USER_ID} ${ARTIFACTORY_HOME} \
&& chmod -R 777 ${ARTIFACTORY_HOME} \
&& chown -R ${ARTIFACTORY_USER_ID}:${ARTIFACTORY_USER_ID} /entrypoint.sh \
&& chmod -R 777 /entrypoint.sh

USER $ARTIFACTORY_USER_ID

HEALTHCHECK --interval=5m --timeout=3s \
  CMD curl -f http://localhost:8080/artifactory || exit 1

# Expose Artifactories data directory
VOLUME ["${ARTIFACTORY_HOME}", "${ARTIFACTORY_HOME}/backup"]

WORKDIR ["${ARTIFACTORY_HOME}"]

EXPOSE 8081

ENTRYPOINT ["/entrypoint.sh"]
