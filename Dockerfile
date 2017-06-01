FROM  oberthur/docker-ubuntu:16.04

RUN   add-apt-repository ppa:vbernat/haproxy-1.7 \
  && apt-get update \
  && apt-get -y upgrade \
  &&  apt-get install -y haproxy bash curl vim jq parallel git ca-certificates --no-install-recommends && \
  apt-get clean -y && \
  rm -rf /var/lib/apt/lists/*


COPY config config
RUN chmod -R +x config




CMD ["bash", "-c", "/config/endpoints_script.sh"]
