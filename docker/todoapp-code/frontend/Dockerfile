# Etape 1 : build de l'application React avec Vite
FROM node:20-alpine AS build

WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Etape 2 : servir les fichiers statiques avec Nginx (image legere)
FROM nginx:alpine

COPY --from=build /app/dist /usr/share/nginx/html
COPY templates/default.conf.template /etc/nginx/templates/default.conf.template

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
