FROM emarsys/kong-dev-docker:1.3.0-centos-4c4df99-bdc635e

RUN luarocks install classic && \
    luarocks install kong-lib-logger --deps-mode=none && \
    luarocks install kong-client 1.0.1
