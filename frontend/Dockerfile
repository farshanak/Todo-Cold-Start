# --- Stage 1: Build (compile TypeScript) ---
FROM node:20-alpine AS build
WORKDIR /build
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci
COPY frontend/tsconfig.json frontend/app.ts frontend/index.html ./
RUN npx tsc

# --- Stage 2: Development (tsc --watch + static server) ---
FROM node:20-alpine AS development
WORKDIR /app
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci && npm install -g http-server
COPY frontend/ ./
EXPOSE 5500
# tsc --watch rebuilds app.js on source changes; http-server serves the folder.
CMD ["sh", "-c", "npx tsc --watch & exec http-server -p 5500 -c-1 ."]

# --- Stage 3: Production (non-root nginx serving static assets) ---
FROM nginxinc/nginx-unprivileged:1.27-alpine AS production
COPY --from=build /build/index.html /usr/share/nginx/html/index.html
COPY --from=build /build/app.js /usr/share/nginx/html/app.js
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD wget -q --spider http://localhost:8080/ || exit 1
