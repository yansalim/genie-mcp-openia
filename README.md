# Genie MCP Server (Docker) — Porta 9998

Este repositório empacota o **Automagik Genie** como **servidor MCP** rodando em **Docker**, expondo endpoints **HTTP/SSE** para integração com o **ChatGPT (Developer Mode)** utilizando a sua assinatura **ChatGPT Plus / Team / Enterprise** — **sem API key** na sua aplicação.

> **Resumo**
>
> - Base: `node:22-alpine` (Node mais recente dentro do container)  
> - Executa `genie mcp` (STDIO) conforme o tutorial do Genie  
> - Publica **`/mcp`** (HTTP stream) e **`/sse`** (SSE) via **mcp-proxy** na **porta 9998**  
> - `docker-compose.yml` com `restart: always`, **healthcheck** e volume para estado  
> - Serviço opcional de **Cloudflare Tunnel** para HTTPS rápido

---

## 📂 Estrutura

- **`Dockerfile`** – Instala `automagik-genie` e `mcp-proxy`, e inicia o proxy em `:9998` spawnando `genie mcp`.
- **`docker-compose.yml`** – Publica `9998:9998`, adiciona healthcheck e volume `./genie:/workspace`.
- **`.env` (opcional)** – Define `MCP_PROXY_API_KEY` para exigir `X-API-Key` nas rotas.

> **Observação**: O ChatGPT (Developer Mode) costuma exigir **HTTPS**. Use o serviço `cloudflared` (incluso) ou seu próprio reverse proxy (Nginx/Traefik) com TLS.

---

## 🚀 Quick Start

### 1) Pré-requisitos

- Docker + Docker Compose no servidor
- (Opcional) Domínio/HTTPS **ou** Cloudflare Tunnel

### 2) Subir o serviço

```bash
# (Opcional) proteger o endpoint com uma API key
echo 'MCP_PROXY_API_KEY=troque-por-uma-chave-forte' > .env

# Build e subida
docker compose build --no-cache
docker compose up -d

# Verificar
docker ps --format 'table {{.Names}}\t{{.Ports}}\t{{.Status}}'
```

### 3) Testes locais

```bash
# Healthcheck
curl -i http://localhost:9998/ping

# SSE (deve retornar cabeçalhos de evento)
curl -i http://localhost:9998/sse

# (se definiu a chave)
curl -i -H 'X-API-Key: troque-por-uma-chave-forte' http://localhost:9998/ping
```

Se tudo certo, você verá `HTTP/1.1 200 OK` no `/ping`.

---

## 🔌 Endpoints

| Método | Caminho | Descrição |
|---|---|---|
| `GET` | `/ping` | Verificação de saúde do proxy |
| `POST` | `/mcp` | Canal **HTTP stream** para o MCP |
| `GET` | `/sse` | **Server-Sent Events** do MCP |

> Com `MCP_PROXY_API_KEY` definido no `.env`, envie **`X-API-Key: <sua-chave>`** nas requisições.

---

## 🧠 Uso com ChatGPT (Developer Mode)

1. **Ative o Developer Mode** no ChatGPT (Settings → Apps & Connectors → Advanced).  
2. Garanta que seu servidor seja acessível por **HTTPS**:
   - **Opção rápida**: rode o túnel Cloudflare (serviço `cloudflared` do Compose).  
   - **Produção**: use Nginx/Traefik com TLS.
3. Em **Settings → Connectors → Create**, cadastre um conector apontando para:
   - **URL do conector**: `https://SEU-DOMINIO-OU-TUNEL/mcp`
   - (Se usar chave) adicione o header `X-API-Key`.
4. Abra um chat em **Developer Mode**, selecione o conector (ex.: *Genie (MCP)*) e peça:  
   > “Use as ferramentas do Genie para <tarefa>.”

> **Cobrança**: a orquestração feita dentro do ChatGPT utiliza **o seu plano ChatGPT** (Plus/Team/Enterprise). Para rodar **fora** do ChatGPT (headless/CI/backend), use APIs com chave e cobrança por tokens.

---

## 🌐 Cloudflare Tunnel (opcional)

O `docker-compose.yml` inclui um serviço `cloudflared` que cria um túnel HTTPS apontando para `genie-mcp:9998`.

```bash
docker compose up -d cloudflared
docker logs -f cloudflared   # anote a URL https://<hash>.trycloudflare.com
```

Use `https://<hash>.trycloudflare.com/mcp` ao criar o conector no ChatGPT.

> Em produção, prefira domínio próprio + TLS para uma URL estável.

---

## ⚙️ Variáveis de ambiente

Crie um `.env` (opcional):

| Variável | Obrigatório | Exemplo/Default | Descrição |
|---|---|---|---|
| `MCP_PROXY_API_KEY` | Não | `troque-por-uma-chave-forte` | Se definido, exige `X-API-Key` nas rotas (`/ping`, `/mcp`, `/sse`). |
| `TZ` | Não | `UTC` | Fuso horário do container. |

> **Não é necessário** `OPENAI_API_KEY` para o ChatGPT usar o MCP. Só use chaves se você quiser que **o próprio servidor** chame LLMs fora do ChatGPT.

---

## 💾 Persistência & Logs

- O volume `./genie:/workspace` guarda **estado** (`.genie/`) e **logs** do serviço.  
- Trate esse diretório como **sensível**, especialmente se suas ferramentas MCP lidarem com arquivos/projetos locais.

---

## 🔄 Atualização

```bash
docker compose build --no-cache
docker compose up -d

# Conferir versões dentro do container
docker exec -it genie-mcp node -v
docker exec -it genie-mcp npm ls -g automagik-genie mcp-proxy
```

---

## 🧪 Diagnóstico (Troubleshooting)

- **404/502 no conector**: confirme a **URL** (use `/mcp`), e que o túnel/proxy aponta para `:9998`.  
- **401 Unauthorized**: faltou `X-API-Key` quando `MCP_PROXY_API_KEY` está definido.  
- **Sem HTTPS**: o ChatGPT costuma **não** acessar HTTP puro → use TLS (Cloudflare Tunnel ou seu proxy).  
- **Sem tools listadas**: reinicie o conector no ChatGPT e verifique os **logs**:

```bash
docker logs -f genie-mcp
```

---

## 🏗️ Arquitetura (alto nível)

```
ChatGPT (Developer Mode)  ⇄  HTTPS  ⇄  [mcp-proxy (/mcp, /sse):9998]  ⇄  (STDIO)  ⇄  automagik-genie mcp
```

- **mcp-proxy** converte HTTP/SSE ⇄ STDIO e gerencia o processo do **Genie**  
- **Genie (MCP)** segue o comando oficial `genie mcp` (Node 18+)

---

## 📜 Licença

Respeite as licenças dos projetos de base (Genie/Automagik, mcp-proxy) e as políticas do provedor de LLM.  
Adapte este repositório ao seu ambiente (domínio, TLS, autenticação).

---

## 💬 Suporte

Abra uma *issue* com:
- Logs (`docker logs -f genie-mcp`)
- Resposta do `/ping` e `/sse`
- Print da configuração do *Connector* (sem segredos)

```bash
# Comandos úteis
docker compose ps
docker logs -f genie-mcp
docker compose restart genie-mcp
```
