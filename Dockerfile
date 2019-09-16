FROM alpine:3.9

RUN mkdir -p /home/app

# Install dependencies: fwatchdog, yq and porta.sh
RUN apk --no-cache add curl bash \
    && echo "Pulling watchdog binary from Github." \
    && curl -sSL https://github.com/openfaas/faas/releases/download/0.15.2/fwatchdog > /usr/bin/fwatchdog \
    && chmod +x /usr/bin/fwatchdog \
    && cp /usr/bin/fwatchdog /home/app \
    && echo "Pulling porta.sh from Github." \
    && curl -sSL https://github.com/data-intuitive/Portash/releases/download/v0.0.8/porta.sh > /usr/bin/porta.sh \
    && chmod +x /usr/bin/porta.sh \
    && echo "Pulling yq from Github." \
    && curl -sSL https://github.com/mikefarah/yq/releases/download/2.4.0/yq_linux_386 > /usr/bin/yq \
    && chmod +x /usr/bin/yq \
    && apk del curl --no-cache

# Add non root user
# RUN addgroup -S app && adduser app -S -G app
# RUN chown app /home/app
# WORKDIR /home/app
# USER app

# fwatchdog config
EXPOSE 8080
ENV fprocess="porta.sh"
ENV write_debug="true"
ENV read_timeout=3600
ENV write_timeout=3600

HEALTHCHECK --interval=3s CMD [ -e /tmp/.lock ] || exit 1
CMD [ "fwatchdog" ]
