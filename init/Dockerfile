FROM alpine:latest
RUN apk --no-cache add curl

WORKDIR /app/data

COPY download.sh .

CMD ["sh", "download.sh"]
