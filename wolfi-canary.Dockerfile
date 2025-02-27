# this is mostly crimed from step 2 in the original Semgrep Dockerfile
# we have a binary; it's built by a GH Action. so we don't need to build it here
# we just need to install the deps and run it
# why can't we run the bare binary? because the rules etc are 
# bundled in pysemgrep, and we need to install that first + wrap the binary
# in it.

# thus, we don't Chainguard's bare wolfi-base image, but rather the python image
# which has all the dependencies we need
FROM cgr.dev/chainguard/python:latest

WORKDIR /pyopengrep

# ensure that base packages are up to date
RUN apk upgrade --no-cache && \
    apk add --no-cache --virtual=.run-deps\
        git git-lfs openssh \
        bash jq curl

# with this build, we need to include the cli
COPY cli ./

# stealing Yoann's build logic
RUN apk add --no-cache --virtual=.build-deps build-base make &&\
     pip install /pyopengrep &&\
     apk del .build-deps

# switch to /usr/local/bin to pull in the opengrep binary
WORKDIR /usr/local/bin

COPY opengrep_manylinux_x86 /usr/local/bin/opengrep

# we don't need the old workdir anymore 
# ensure `/src/` is owned by the nonroot user
# (this is an artifact of the original Semgrep Dockerfile)
# we also need to ensure that the .gitconfig is owned by the nonroot user
RUN chown -R nonroot:nonroot /src && \
    chown -R nonroot:nonroot ~nonroot/.gitconfig && \
    rm -rf /pyopengrep

# never run a chainguard image as root, it makes Richard Stallman cry
USER nonroot

# transparency: put the Dockerfile in the image
# Let the user know how their container was built
COPY wolfi-canary.Dockerfile /Dockerfile

# bare minimum entrypoint so users can construct their own command strings
ENTRYPOINT ["opengrep"]

# if you read this far down: honk.