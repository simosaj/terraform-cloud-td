FROM debian:latest AS tools
RUN apt-get update \
    && apt-get install -y --no-install-recommends bash htop vim net-tools \
    && rm -rf /var/lib/apt/lists/*
ENV OWNER=Mohamed
CMD ["sleep", "3600"]

FROM tools
RUN useradd --create-home nonroot
USER nonroot
