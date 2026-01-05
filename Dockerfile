# stage 1
FROM node:alpine AS build-direr
WORKDIR /build-dir
COPY package.json ./
RUN npm install --production
# stage 2
FROM node:alpine
WORKDIR /user
RUN addgroup -S roboshop && adduser -S roboshop -G roboshop
RUN chown roboshop:roboshop /user
USER roboshop
EXPOSE 8080
ENV NODE_ENV=production
ENV MONGO='true' 
COPY --from=build-direr /build-dir/node_modules ./node_modules
COPY server.js .
CMD ["node", "server.js"]
# Environment=REDIS_HOST=redis
# Environment=MONGO_URL="mongodb://mongodb:27017/users"