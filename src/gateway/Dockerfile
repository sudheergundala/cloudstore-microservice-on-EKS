FROM node:26-slim AS builder
WORKDIR /app
COPY package.json package-lock.json tsconfig.json ./
RUN npm ci  # this will install all the dependencies
COPY src/ ./src/
RUN npm run build  # this will run tsc and post the output to dist
RUN npm ci --omit=dev # this will omit the devdependencies
FROM node:26-slim
WORKDIR /app
RUN useradd --create-home appuser # we need to use the non-root user.so we are creating the user and home directory.
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json ./package.json
RUN chown -R appuser:appuser /app/
USER appuser
EXPOSE 3000
CMD ["node", "dist/server.js"]