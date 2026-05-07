FROM node:18-alpine
WORKDIR /app
COPY package.json .
RUN npm install
COPY next.config.js ./
COPY pages ./pages
EXPOSE 3000
CMD ["npm", "run", "dev"]
