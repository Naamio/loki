FROM ibmcom/swift-ubuntu-runtime:4.0

ADD .build/release/ /usr/share/loki/

ENV PORT=8000
ENV LOG=INFO

EXPOSE ${PORT}

WORKDIR /usr/share/loki/

ENTRYPOINT ["/usr/share/loki/LokiCollector"]
