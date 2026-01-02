# Guia de Deploy VPS (Portainer) 🚀

Este guia explica como pegar as alterações que fizemos (WuzAPI V1 e Fixes) e colocar para rodar no seu servidor VPS usando Portainer.

## Pré-requisitos

1.  **Conta no Docker Hub**: Crie uma em [hub.docker.com](https://hub.docker.com/) (Grátis).
2.  **Docker Instalado Localmente**: Para construir a imagem.
3.  **Portainer na VPS**: Já rodando.

---

## Passo 1: Construir e Publicar a Imagem

Como alteramos o código (Ruby), precisamos criar uma "nova versão" do Chatwoot.

**No seu terminal local (VS Code):**

1.  Faça login no Docker Hub:

    ```bash
    docker login
    # Digite seu usuário e senha
    ```

2.  **Configurar Buildx (Multi-Arch)**:
    Garante que a imagem funcione tanto em servidores Intel/AMD (VPS Comum) quanto Apple Silicon.

    ```bash
    docker buildx create --use --name xbuilder || true
    docker buildx inspect --bootstrap

    docker buildx build \
      --platform linux/amd64,linux/arm64 \
      -f docker/Dockerfile \
      -t rodrigobm10/chatwoot:wuzapi-v1 \
      --push .
    ```

---

## Passo 2: Configurar no Portainer (VPS)

1.  Acesse seu Portainer.
2.  Vá em **Stacks** -> **Add stack**.
3.  Dê o nome `chatwoot`.
4.  Cole o seguinte conteúdo no Editor Web:

> **ATENÇÃO**: Substitua `image: SEU_USUARIO/chatwoot:v2` pela imagem que você criou no passo anterior.

```yaml
version: "3.8"

services:
  base: &base
    image: rodrigobm10/chatwoot:wuzapi-v2 # <--- SUA IMAGEM CORRETA
    env_file: .env
    volumes:
      - storage_data:/app/storage

  rails:
    <<: *base
    depends_on:
      - postgres
      - redis
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - RAILS_ENV=production
      - INSTALLATION_ENV=docker
    entrypoint: docker/entrypoints/rails.sh
    command: ["bundle", "exec", "rails", "s", "-p", "3000", "-b", "0.0.0.0"]
    restart: always
    deploy:
      resources:
        limits:
          memory: 2048M

  sidekiq:
    <<: *base
    depends_on:
      - postgres
      - redis
    environment:
      - NODE_ENV=production
      - RAILS_ENV=production
      - INSTALLATION_ENV=docker
    command: ["bundle", "exec", "sidekiq", "-C", "config/sidekiq.yml"]
    restart: always
    deploy:
      resources:
        limits:
          memory: 1024M

  postgres:
    image: pgvector/pgvector:pg16
    restart: always
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB=chatwoot
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=suasenhabancoforte

  redis:
    image: redis:alpine
    restart: always
    command: ["sh", "-c", 'redis-server --requirepass "$REDIS_PASSWORD"']
    environment:
      - REDIS_PASSWORD=suasenharedis
    volumes:
      - redis_data:/data

volumes:
  storage_data:
  postgres_data:
  redis_data:
```

5.  **Variáveis de Ambiente (.env)**:
    No Portainer, adicione as variáveis de ambiente ("Environment variables"). Copie do seu `.env` local, mas **ATENÇÃO**:
    - `FRONTEND_URL`: Deve ser o seu domínio real (ex: `https://chat.suaempresa.com`).
    - `POSTGRES_PASSWORD`: Use a mesma definida no YAML acima.
    - `REDIS_PASSWORD`: Use a mesma definida no YAML acima.
    - `ACTIVE_RECORD_ENCRYPTION_...`: **CRÍTICO!** Copie as chaves do seu arquivo local. Se mudar, perde o acesso aos tokens do WuzAPI.

---

## Passo 3: Migrações (Primeiro Deploy)

Após subir a stack, o banco de dados estará vazio ou desatualizado e você precisa rodar as migrações:

1.  No Portainer, entre no container `chatwoot_rails` (clique no ícone de Console `>_`).
2.  Execute:
    ```bash
    bundle exec rails db:prepare
    # Ou se já existir banco e só quiser atualizar:
    bundle exec rails db:migrate
    ```

---

## Passo 4: Automação (Webhook)

Para atualizar automaticamente quando você der `docker push`:

1.  No Portainer, na sua Stack ou Service (`chatwoot_rails` e `chatwoot_sidekiq`), ative "Service Webhook".
2.  Ele vai gerar uma URL (ex: `https://portainer.seu.com/api/webhooks/...`).
3.  Configure seu CI/CD (GitHub Actions) ou simplesmente chame essa URL com um POST após o push.
    - _Nota: O Portainer Business Edition tem isso facilitado. No Community Edition, você pode precisar de um script extra para atualizar a stack inteira._

**Pronto!** Seu Chatwoot personalizado com WuzAPI estará no ar.
