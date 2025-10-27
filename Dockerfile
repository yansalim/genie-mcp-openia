# Node estável (22-alpine no momento)
FROM node:22-alpine

# Dependências mínimas (git é pré-requisito do Genie)
RUN apk add --no-cache git bash curl

# Instala o CLI do Genie e o proxy MCP (Node)
# OBS: seguindo o README do Genie -> "npm i -g automagik-genie@latest"
RUN npm i -g automagik-genie@latest mcp-proxy@latest

# Diretório de trabalho + persistência do estado do Genie
WORKDIR /workspace
RUN mkdir -p /workspace/.genie /workspace/logs

# Variáveis opcionais (segurança do proxy e TZ)
ENV MCP_PROXY_API_KEY="" \
    TZ=UTC

EXPOSE 9998

# Sobe o proxy na :9998 e spawna o Genie MCP em STDIO
# - O proxy publica /mcp (HTTP stream) e /sse
# - Tudo que vier via HTTP/SSE é encaminhado para "npx automagik-genie mcp"
CMD ["sh","-lc", "\
  echo '>> starting mcp-proxy on :9998 -> automagik-genie mcp' && \
  npx mcp-proxy --port 9998 -- npx automagik-genie mcp \
"]