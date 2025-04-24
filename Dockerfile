FROM nginx:alpine

RUN apk add --no-cache gettext

COPY nginx.conf /etc/nginx/nginx.conf
COPY conf.d /etc/nginx/templates
COPY entrypoint.sh /entrypoint.sh
RUN rm /etc/nginx/conf.d/default.conf

RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

