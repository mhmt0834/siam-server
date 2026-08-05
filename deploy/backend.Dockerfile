ARG RUNTIME_IMAGE=eclipse-temurin:8-jre-jammy
FROM ${RUNTIME_IMAGE}

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --system --gid 10001 siam \
    && useradd --system --uid 10001 --gid siam --home-dir /app --shell /usr/sbin/nologin siam

WORKDIR /app
COPY siam-system/system-provider/target/siam-server.jar /app/siam-server.jar
RUN mkdir -p /app/logs && chown -R siam:siam /app

USER siam
EXPOSE 9200

ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar /app/siam-server.jar"]
