FROM ibmcom/swift-ubuntu-runtime:4.2

ADD .build/release/ /usr/share/loki/

ENV LOKI_SERVICE_PORT=8000
ENV LOG=INFO

EXPOSE ${LOKI_SERVICE_PORT}

WORKDIR /usr/share/loki/

ENTRYPOINT ["/usr/share/loki/LokiCollector"]
