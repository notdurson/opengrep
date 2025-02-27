# this is mostly crimed from step 2 in the original Semgrep Dockerfile
# we have a binary; it's built by a GH Action. so we don't need to build it here
# we just need to install the deps and run it
# why can't we run the bare binary? because the rules etc are 
# bundled in pysemgrep, and we need to install that first + wrap the binary
# in it.

# thus, we don't Chainguard's bare wolfi-base image, but rather the python image
# which has all the dependencies we need

# we start with the dev image so we can install the CLI in the same container
# the bare python image doesn't have a shell
FROM cgr.dev/chainguard/python:latest-dev as builder

# we don't want the python bytecode
ENV LANG=C.UTF-8
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /pyopengrep

# python images run as nonroot by default so we need to switch to root
# for package operations
USER root

# ensure that base packages are up to date
# minimal deps please
RUN apk upgrade --no-cache && \
    apk add --no-cache --virtual=.run-deps\
        git git-lfs openssh \
        bash jq curl

# with this build, we need to include the cli
COPY cli ./

# since we're gonna copy this to a more minimal image,
# we need to create a venv and install the CLI in it
RUN python -m venv venv
ENV PATH="/pyopengrep/venv/bin:$PATH"

# stealing Yoann's build logic to build the CLI
RUN apk add --no-cache --virtual=.build-deps build-base make &&\
     pip install /pyopengrep &&\
     apk del .build-deps


# ensure `/src/` is owned by the nonroot user
# (this is an artifact of the original Semgrep Dockerfile)
# this needs to be done in the builder stage because the final container
# doesn't have a shell so we can't run any commands
RUN RUN mkdir /src && chown -R nonroot:nonroot /src


# now we can use a more barebones image
FROM cgr.dev/chainguard/python:latest

WORKDIR /pyopengrep
# copy everything we need from the builder stage
COPY --from=builder /pyopengrep/venv/bin /pyopengrep/venv/bin
COPY --from=builder /src /src

# same path modification as before
ENV PATH="/pyopengrep/venv/bin:$PATH"

# switch to /usr/local/bin to pull in the opengrep binary
WORKDIR /usr/local/bin

COPY opengrep_manylinux_x86 /usr/local/bin/opengrep

# never run a chainguard image as root, they aren't designed for it
USER nonroot

# transparency: put the Dockerfile in the image
# this shows the user how the image was built
COPY wolfi-canary.Dockerfile /Dockerfile

# bare minimum entrypoint so users can construct their own command strings
ENTRYPOINT ["opengrep"]

# if you read this far down: honk.