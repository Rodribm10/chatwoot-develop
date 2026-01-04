# Guia de Configuração e Preview Local (Chatwoot Develop)

**Objetivo:** Rodar o ambiente de desenvolvimento `chatwoot-develop` localmente via Docker para validação de funcionalidades (ex: Integrações WhatsApp).

## 🚀 Como Iniciar Rapidamente

1.  **Vá para a pasta do projeto:**

    ```bash
    cd /Users/user/Chatwoot/chatwoot-develop
    ```

2.  **Suba os containers:**

    ```bash
    docker-compose up
    ```

    _Aguarde até ver logs indicando que `rails` (porta 3000) e `vite` (porta 3036) estão prontos._

3.  **Acesse:**
    Acesse [http://localhost:3000](http://localhost:3000).
    - **Login:** `rodrigobm10@gmail.com`
    - **Senha:** `Password123!`

---

## 🛠️ Solução de Problemas Comuns (Troubleshooting)

Se algo der errado, consulte os erros abaixo que enfrentamos e como resolvemos:

### 1. Erro: `ActiveRecord::NoDatabaseError`

**Sintoma:** Tela vermelha dizendo que o banco `chatwoot_dev` não existe.
**Causa:** O banco de dados Postgres foi iniciado, mas o banco específico da aplicação não foi criado.
**Solução:**
Abra um **novo terminal** na pasta do projeto e rode:

```bash
docker-compose exec rails bundle exec rails db:create db:migrate
```

_Se pedir para rodar seeds, adicione `db:seed` ao final._

### 2. Erro: `No account found` (Login travado)

**Sintoma:** Você faz login, mas cai numa tela branca dizendo "No account found".
**Causa:** O usuário existe no banco, mas não tem vínculo (`AccountUser`) com nenhuma conta.
**Solução:**
Rode este comando (SQL Direto) para forçar o vínculo e liberar o acesso:

```bash
docker-compose exec postgres psql -U postgres -d chatwoot_dev -c "INSERT INTO account_users (user_id, account_id, role, created_at, updated_at) VALUES (1, 1, 0, NOW(), NOW()) ON CONFLICT DO NOTHING;"
```

### 3. Erro no Vite: `Activating bundler (2.5.11) failed`

**Sintoma:** O container `vite` cai com erro dizendo que não achou o bundler 2.5.11.
**Causa:** A imagem Docker pode ter uma versão do Ruby/Bundler diferente do `Gemfile.lock`.
**Solução:**
Editamos o `docker-compose.yaml` para instalar a versão correta antes de rodar:

```yaml
# docker-compose.yaml
vite:
  command: sh -c "gem install bundler:2.5.11 && bin/vite dev"
```

### 4. Erro de Conexão com Banco (Porta 5438 vs 5432)

**Sintoma:** O Rails não conecta no Postgres (`Connection refused`).
**Causa:** O arquivo `.env` local define `POSTGRES_PORT=5438` (porta externa), mas dentro da rede Docker o Rails deve falar na porta interna `5432`.
**Solução:**
Forçamos a porta interna no `docker-compose.yaml` (services `rails`, `sidekiq`, `migrate`):

```yaml
environment:
  - POSTGRES_PORT=5432
  - DATABASE_URL= # Deixar vazio para não pegar do .env
```

### 5. Erro no Build Frontend: `PromoBanner.vue not found`

**Sintoma:** O `vite` falha ao compilar dizendo que não acha esse arquivo.
**Causa:** Arquivo presente na branch `main` mas faltando na `develop`.
**Solução:**
Criar o arquivo manualmente em `app/javascript/dashboard/components-next/banner/PromoBanner.vue` (copiando do repo principal).

---

## 📝 Comandos Úteis

- **Reiniciar serviços (limpa alguns erros voláteis):**

  ```bash
  docker-compose restart rails sidekiq
  ```

- **Limpar Cache (Redis):**

  ```bash
  docker-compose exec redis redis-cli FLUSHALL
  ```

- **Resetar tudo (Cuidado: apaga dados):**
  ```bash
  docker-compose down -v
  ```
