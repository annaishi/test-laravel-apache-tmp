FROM node:lts

COPY ./laravel /var/www/html

WORKDIR /var/www/html

RUN if [ -f package.json ]; then \
    npm install; \
    fi

EXPOSE 5173
# exposeでは実際のポートに影響しない

ENTRYPOINT [ "bash", "-c", "if [ -f package.json ]; then npm run dev; else echo 'No package.json found. Keeping Container alive.' && tail -f /dev/null; fi" ]