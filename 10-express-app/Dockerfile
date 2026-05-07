FROM node:18-alpine
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm install
COPY app.js .
EXPOSE 3000
CMD ["npm", "start"]
