# Gleefy billing API. Build from the repository root:
#   docker build -f apps/api/Dockerfile -t gleefy-api .
# Configuration comes from environment variables (see apps/api/.env.example); none are baked in.

FROM node:22-bookworm-slim AS build
WORKDIR /repo
RUN corepack enable
COPY . .
RUN pnpm install --frozen-lockfile --filter gleefy --filter "@gleefy/api..."
RUN pnpm --filter "@gleefy/api^..." run build && pnpm --filter @gleefy/api run build
# A self-contained copy of the API with production dependencies only.
RUN pnpm --filter @gleefy/api deploy --prod --legacy /out

FROM node:22-bookworm-slim
ENV NODE_ENV=production PORT=4000
WORKDIR /app
COPY --from=build --chown=node:node /out ./
USER node
EXPOSE 4000
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s \
  CMD node -e "fetch('http://127.0.0.1:'+process.env.PORT+'/health').then(r=>process.exit(r.ok?0:1),()=>process.exit(1))"
CMD ["node", "dist/main.js"]
