ARG MOSQUITTO_VERSION
FROM eclipse-mosquitto:${MOSQUITTO_VERSION}

# Install mosquitto clients for healthcheck
RUN apk add --no-cache mosquitto-clients

# Create directories
RUN mkdir -p /mosquitto/config /mosquitto/data /mosquitto/log

# Set proper permissions
RUN chown -R mosquitto:mosquitto /mosquitto

# Copy default config file (will be overridden by volume mount)
COPY mosquitto.conf /mosquitto/config/

EXPOSE 1883 9001

# Use the default mosquitto command from the base image
CMD ["/usr/sbin/mosquitto", "-c", "/mosquitto/config/mosquitto.conf"]

# COPY mosquitto-docker-entrypoint.sh /
# ENTRYPOINT ["sh", "./mosquitto-docker-entrypoint.sh"]
# CMD ["/usr/sbin/mosquitto","-c","/mosquitto/config/mosquitto.conf"]
