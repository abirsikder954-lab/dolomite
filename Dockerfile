# Dolomite External — licence server (Render Docker runtime)
#
# Render's native Node runtime is preferred, but a service created manually
# falls back to Docker when the repository root has no package.json — and
# then it looks for exactly this file. Having it here means the service
# builds either way.
#
# The server may be a committed server/ folder or may live inside
# Dolomite-monorepo.zip / dolomite-dashboard.zip. The build step below
# handles all three.

FROM node:22-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends unzip ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY . /src

WORKDIR /app
RUN set -e; \
    if [ -f /src/server/server.js ]; then \
        echo "using the committed server/ folder"; \
        mkdir -p /app/server && cp -R /src/server/. /app/server/; \
    elif [ -f /src/server.js ]; then \
        echo "using the repository root"; \
        mkdir -p /app/server; \
        for item in server.js package.json lib public worker test scripts data; do \
            [ -e "/src/$item" ] && cp -R "/src/$item" /app/server/ || true; \
        done; \
    else \
        for zip in Dolomite-monorepo.zip dolomite-dashboard.zip; do \
            [ -f "/src/$zip" ] || continue; \
            echo "extracting server/ from $zip"; \
            rm -rf /tmp/dolo && mkdir -p /tmp/dolo; \
            unzip -q "/src/$zip" -d /tmp/dolo || true; \
            if [ -f /tmp/dolo/server/server.js ]; then \
                mkdir -p /app/server && cp -R /tmp/dolo/server/. /app/server/; \
                break; \
            fi; \
            if [ -f /tmp/dolo/server.js ]; then \
                mkdir -p /app/server && cp -R /tmp/dolo/. /app/server/; \
                break; \
            fi; \
        done; \
    fi; \
    if [ ! -f /app/server/server.js ]; then \
        echo "ERROR: server/server.js was not found."; \
        echo "Upload Dolomite-monorepo.zip to the repository root, or commit the server/ folder."; \
        exit 1; \
    fi; \
    cd /app/server && npm install --omit=dev && mkdir -p /var/data

ENV NODE_ENV=production
ENV PORT=10000
ENV DATA_DIR=/var/data

EXPOSE 10000
WORKDIR /app/server
CMD ["node", "server.js"]
