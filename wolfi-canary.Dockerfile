# Build stage to set permissions
FROM cgr.dev/chainguard/wolfi-base

WORKDIR /app

COPY opengrep_manylinux_x86 /app/opengrep

RUN chmod +x /app/opengrep

RUN adduser -D nonroot
USER nonroot

ENTRYPOINT ["/app/opengrep ci --sarif --sarif-output opengrep_report.sarif --config auto"]