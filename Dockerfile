# Best Practice: Pin to a specific Node version (e.g., 20-alpine) rather than the generic 'alpine' to ensure deterministic builds.
FROM node:alpine AS builder

WORKDIR /build-dir

# Copy only package files first. This caches the 'npm install' step unless dependencies change, speeding up builds.
COPY ./app-code/package*.json ./
RUN npm install --omit=dev 

# -----------------------------------
# Stage 2: Production Image
# -----------------------------------
FROM node:alpine

# Install dumb-init. Node.js doesn't handle PID 1 (OS signals) well in containers; this prevents zombie processes and handles graceful shutdowns.
RUN apk add --no-cache dumb-init

# Use explicit UID/GID (1001) instead of just names. This is critical for Kubernetes SecurityContext predictability.
RUN addgroup -g 1001 roboshop && \
    adduser -u 1001 -G roboshop -s /bin/sh -D roboshop

WORKDIR /user-app

# Set the Node environment to production for performance optimizations
ENV NODE_ENV=production
ENV MONGO=true
ENV MONGO_URL="mongodb://mongodb:27017/users"

# Change ownership of the directory to our non-root user
RUN chown roboshop:roboshop /user-app

# Switch to the non-root user BEFORE copying application code to ensure correct ownership
USER 1001

# Copy files and explicitly set ownership to the non-root user
COPY --chown=1001:1001 ./app-code/server.js .
COPY --chown=1001:1001 --from=builder /build-dir/node_modules ./node_modules 

# Document the port the container listens on
EXPOSE 8080

# Use dumb-init to wrap the Node process for proper signal handling
CMD ["dumb-init", "node", "server.js"]