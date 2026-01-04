# Guia de Deploy em Produção (Docker)

## 🚨 REGRA DE OURO: Imagem Docker

Ao configurar o arquivo `docker-compose.production.yaml` ou qualquer orquestrador (Portainer, Coolify, etc), **JAMAIS** use a imagem oficial do Chatwoot se você quiser ver suas modificações.

### ❌ ERRADO (Baixa o Chatwoot Original)

```yaml
image: chatwoot/chatwoot:latest
```

_Se usar isso, nenhuma alteração de código, cor ou funcionalidade feita por nós vai aparecer. O servidor vai baixar a versão da empresa Chatwoot._

### ✅ CORRETO (Baixa a NOSSA versão modificada)

```yaml
image: ghcr.io/rodribm10/chatwoot-jasmine:latest
```

_Esta é a imagem que o nosso GitHub Actions constrói toda vez que fazemos um push. Ela contém todas as nossas personalizações._

---

## Passo a Passo para Deploy

1. **Commit & Push**: Envie suas alterações para o repositório (`git push`).
2. **Aguarde o Build**: Verifique na aba "Actions" do GitHub se o workflow "Build and Push" terminou com sucesso (isso atualiza a imagem no GHCR).
3. **Atualize a Stack**:
   - Vá no Portainer/Servidor.
   - Garanta que está usando a imagem `ghcr.io/rodribm10/chatwoot-jasmine:latest`.
   - Force o download da nova imagem (Pull latest image / Re-pull).
   - Reinicie os containers.

## Por que isso acontece?

O Docker funciona por camadas. A imagem `chatwoot/chatwoot` é mantida pela equipe do Chatwoot. A imagem `ghcr.io/rodribm10/chatwoot-jasmine` é a nossa cópia (fork) onde aplicamos as melhorias. Se apontarmos para a oficial, estamos efetivamente "resetando" o app para o padrão de fábrica.
