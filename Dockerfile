# ─── Stage 1: Build ──────────────────────────────────────
FROM node:22-alpine AS builder

WORKDIR /app

# Install dependencies (cached layer)
COPY package.json package-lock.json ./
RUN npm ci

# Copy source and build
COPY . .
RUN npm run build

# ─── Stage 2: Serve ──────────────────────────────────────
FROM nginx:alpine

LABEL maintainer="sj yw <yyzq-cf@github.com>"
LABEL org.opencontainers.image.title="word-atlas"
LABEL org.opencontainers.image.description="词光 · Word Atlas — Illustrated IELTS vocabulary PWA"
LABEL org.opencontainers.image.source="https://github.com/yyzq-cf/word-atlas"
LABEL org.opencontainers.image.licenses="MIT"

# Remove default nginx static assets
RUN rm -rf /usr/share/nginx/html/*

# Copy built assets from builder
COPY --from=builder /app/dist /usr/share/nginx/html

# Custom nginx config: SPA fallback + gzip
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -q --spider http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
