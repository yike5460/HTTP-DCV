# FROM nginx:1.19.3
FROM openresty/openresty:1.21.4.1-amzn2

ENV CERTBOT_DNS_AUTHENTICATORS \
    cloudflare \
    cloudxns \
    digitalocean \
    dnsimple \
    dnsmadeeasy \
    gehirn \
    google \
    linode \
    luadns \
    nsone \
    ovh \
    rfc2136 \
    route53 \
    sakuracloud

# Install all necessities for certbot
RUN set -ex && \
    yum update -y && \
    yum install -y \
        build-essential \
        cargo \
        curl \
        libffi7 \
        libffi-dev \
        libssl-dev \
        openssl \
        procps \
        python3 \
        python3-dev \
    && \
# Install certbot and supported plugins
    curl -L 'https://bootstrap.pypa.io/get-pip.py' | python3 && \
    pip3 install -U cffi certbot \
    $(echo $CERTBOT_DNS_AUTHENTICATORS | sed 's/\(^\| \)/\1certbot-dns-/g') && \
# Remove everything that is no longer necessary.
    # yum remove -y \
    #     build-essential \
    #     cargo \
    #     curl \
    #     libffi-dev \
    #     libssl-dev \
    #     python3-dev \
    # && \
    # yum autoremove -y && \
    # yum clean && \
    # rm -rf /var/lib/apt/lists/* && \
    # rm -rf /root/.cache && \
    # rm -rf /root/.cargo && \

# Create new user and set correct permissions.
    useradd -r -s /sbin/nologin nginx && \
    mkdir -p /var/www/letsencrypt && \
    mkdir -p /etc/nginx/user_conf.d && \
    chown -R nginx:nginx /var/www /etc/nginx/user_conf.d && \
# Make sure there are no surprise config files inside the config folder.
    rm -f /etc/nginx/conf.d/*

# Copy in our "default" Nginx server configurations, which make sure that the
# ACME challenge requests are correctly forwarded to certbot and then redirects
# everything else to HTTPS.
COPY nginx_conf.d/ /etc/nginx/conf.d/

# Copy utils scripts
COPY scripts/ /scripts
RUN chmod +x -R /scripts

# Create health check file for openresty
RUN mkdir -p /usr/local/openresty/nginx/html/health && \
    touch /usr/local/openresty/nginx/html/health/200.html

# Create a volume to have persistent storage for the obtained certificates.
VOLUME /etc/letsencrypt

EXPOSE 443
EXPOSE 80

# Change the container's start command to launch our Nginx and certbot
# management script.
# CMD [ "/scripts/start_nginx_certbot.sh" ]

# Run nginx
CMD ["nginx", "-g", "daemon off;"]




