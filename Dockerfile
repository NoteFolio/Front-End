FROM node:18-bullseye as development

WORKDIR /workspace

COPY package*.json ./

RUN npm install

COPY . .

EXPOSE 3000 3001

CMD ["npm", "start"]

FROM node:18-bullseye as build

WORKDIR /workspace

COPY package*.json ./

RUN npm ci --only=production && npm cache clean --force

RUN npm install

COPY . .

RUN npm run build

FROM nginx:alpine as production

COPY --from=build /workspace/build /usr/share/nginx/html

RUN echo 'server { \
    listen 80; \
    server_name localhost; \
    root /usr/share/nginx/html; \
    index index.html; \
    location / { \
        try_files $uri $uri/ /index.html; \
    } \
    location /static/ { \
        expires 1y; \
        add_header Cache-Control "public, immutable"; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"] 