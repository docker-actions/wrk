ARG ROOTFS=/build/rootfs

FROM alpine:3.19 as build

ARG ROOTFS
ARG VERSION=4.2.0
ARG REQUIRED_PACKAGES="libgcc alpine-baselayout-data"

# Install pre-requisites
RUN apk --no-cache add bash git alpine-sdk linux-headers perl curl

# Build pre-requisites
RUN bash -c 'mkdir -p ${ROOTFS}/{bin,sbin,usr/share,usr/bin,usr/sbin,usr/lib,/usr/local/bin,etc,container_user_home}'

# Initialize ROOTFS
RUN apk add --root ${ROOTFS} --update-cache --initdb \
      && cp -r /etc/apk/repositories ${ROOTFS}/etc/apk/repositories \
      && cp -r /etc/apk/keys ${ROOTFS}/etc/apk/keys

RUN apk --no-cache add -p ${ROOTFS} $REQUIRED_PACKAGES

RUN mkdir -p wrk && curl -L https://github.com/wg/wrk/archive/refs/tags/${VERSION}.tar.gz | tar -xz  -C .

WORKDIR wrk-${VERSION}

RUN make

RUN cp wrk ${ROOTFS}/usr/local/bin

# Move /sbin out of the way
RUN mv ${ROOTFS}/sbin ${ROOTFS}/sbin.orig \
      && mkdir -p ${ROOTFS}/sbin \
      && for b in ${ROOTFS}/sbin.orig/*; do \
           echo 'cmd=$(basename ${BASH_SOURCE[0]}); exec /sbin.orig/$cmd "$@"' > ${ROOTFS}/sbin/$(basename $b); \
           chmod +x ${ROOTFS}/sbin/$(basename $b); \
         done

COPY entrypoint.sh ${ROOTFS}/usr/local/bin/entrypoint.sh
RUN chmod +x ${ROOTFS}/usr/local/bin/entrypoint.sh

RUN rm -rf ${ROOTFS}/etc/apk

FROM actions/bash:5.2.21-1-alpine3.19 as runtime

LABEL maintainer = "ilja+docker@bobkevic.com"

ARG ROOTFS

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

COPY --from=build ${ROOTFS} /

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
