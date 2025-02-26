# Build stage to set permissions
FROM cgr.dev/chainguard/wolfi-base

WORKDIR /app

COPY opengrep_manylinux_x86 /app/opengrep

RUN chmod +x /app/opengrep && ln -s /app/opengrep /usr/local/bin/opengrep

USER nonroot

ENTRYPOINT ["opengrep"]