# Build stage to set permissions
FROM cgr.dev/chainguard/wolfi-base

WORKDIR /app

COPY opengrep_manylinux_x86 /app/opengrep

RUN chmod +x /app/opengrep && ln -s /app/opengrep /usr/local/bin/opengrep

# Chainguard images run as nonroot by default so we need to switch to root
# for package operations
USER root

# ensure `/src/` is owned by the nonroot user
# (this is an artifact of the original Semgrep Dockerfile)
# this needs to be done in the builder stage because the final container
# doesn't have a shell so we can't run any commands
RUN mkdir /src && chown -R nonroot:nonroot /src

COPY opengrep_manylinux_x86 /usr/bin/opengrep
RUN chmod +x /usr/bin/opengrep

# never run a chainguard image as root, they aren't designed for it
USER nonroot

# transparency: put the Dockerfile in the image
# this shows the user how the image was built
COPY wolfi-canary.Dockerfile /Dockerfile

# bare minimum entrypoint so users can construct their own command strings
ENTRYPOINT ["opengrep"]