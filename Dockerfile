FROM alpine:3 

RUN ["/bin/sh", "-c", "apk add --update --no-cache bash ca-certificates curl git jq openssh"]

COPY ["src", "/src/"]

RUN git config --global url."https://oauth2:${GH_PAT}@github.com/${GH_ORG}".insteadOf "https://github.com/"

ENTRYPOINT ["/src/main.sh"]
