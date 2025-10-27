# Node estável (Debian slim para compatibilidade com binários do Forge)
FROM node:22-bookworm-slim

# Dependências mínimas (git é pré-requisito do Genie)
RUN apt-get update && \
    apt-get install -y --no-install-recommends git curl ca-certificates bash unzip && \
    rm -rf /var/lib/apt/lists/*

# Instala o CLI do Genie, Forge backend e o proxy MCP (Node)
# OBS: fixado em versões estáveis até o bug do onboarding ser corrigido
RUN npm i -g automagik-genie@2.5.3 automagik-forge@0.4.5 mcp-proxy@latest && \
    GLOBAL_NODE_MODULES=$(npm root -g) && \
    chown -R node:node "$GLOBAL_NODE_MODULES" /usr/local/bin

# Diretório de trabalho + persistência do estado do Genie
WORKDIR /workspace
RUN mkdir -p /workspace/.genie /workspace/logs && \
    chown -R node:node /workspace

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER node

# Variáveis opcionais (segurança do proxy e TZ)
ENV MCP_PROXY_API_KEY="" \
    TZ=UTC

EXPOSE 8887 9998

# Sobe Forge + MCP proxy (HTTP/SSE) escutando em :9998
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
