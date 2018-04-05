FROM sergef/docker-library-alpine:edge as builder

ENV GOPATH /go

ENV VERSION v2.2.1
ENV BUILD_PATH /go/src/github.com/prometheus/prometheus
ENV BUILD_GIT_URL https://github.com/prometheus/prometheus.git

RUN apk add --no-cache \
    build-base \
    git \
    go@community \
    make \
    musl-dev

RUN mkdir -p ${BUILD_PATH} \
  && git clone ${BUILD_GIT_URL} -b ${VERSION} ${BUILD_PATH} \
  && make -C ${BUILD_PATH} build

FROM sergef/docker-library-alpine:edge

EXPOSE 9090
WORKDIR /prometheus

ENV BUILD_PATH /go/src/github.com/prometheus/prometheus

COPY --from=builder ${BUILD_PATH}/prometheus /bin/prometheus
COPY --from=builder ${BUILD_PATH}/promtool /bin/promtool
COPY --from=builder ${BUILD_PATH}/console_libraries/ /usr/share/prometheus/
COPY --from=builder ${BUILD_PATH}/consoles/ /usr/share/prometheus/
COPY --from=builder ${BUILD_PATH}/documentation/examples/prometheus.yml  /etc/prometheus/prometheus.yml

RUN ln -s /usr/share/prometheus/console_libraries \
    /usr/share/prometheus/consoles/ \
    /etc/prometheus/ \
  && chown -R nobody:nogroup /etc/prometheus /prometheus

USER nobody

ENTRYPOINT [ "/sbin/tini", "--", "/bin/prometheus" ]
CMD [ "--config.file=/etc/prometheus/prometheus.yml", \
  "--storage.tsdb.path=/prometheus", \
  "--web.console.libraries=/usr/share/prometheus/console_libraries", \
  "--web.console.templates=/usr/share/prometheus/consoles" ]
