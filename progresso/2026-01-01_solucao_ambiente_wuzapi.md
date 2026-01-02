# Solução de Problemas: Ambiente Dev, Banco de Dados e WuzAPI

### Data: 01/01/2026

Este documento registra os problemas críticos encontrados durante a configuração do ambiente de desenvolvimento Chatwoot + WuzAPI e suas soluções definitivas.

---

## 1. O Problema do Banco de Dados "Fantasma" (Vazio)

**Sintoma:** Ao reiniciar, o Rails apresentava erro de migrações pendentes ou `PG::UndefinedTable: relation "messages" does not exist`, mesmo o sistema tendo funcionado minutos antes.
**Causa:**
O ambiente possui duas instâncias de Postgres:

1.  **Porta 5432:** Instância vazia/quebrada (padrão local ou outro container).
2.  **Porta 5438:** Instância Docker correta (`chatwoot-develop-postgres-1`) contendo os dados.
    O Rails, por padrão, tentava conectar na 5432.

**Solução:**
Forçar a variável de ambiente `POSTGRES_PORT` no comando de inicialização.

```bash
export POSTGRES_PORT=5438
```

---

## 2. O Problema do Ruby/Bundler (Ambiente Shell)

**Sintoma:** Erros como `Gem::GemNotFoundException`, `ruby 2.6.10` ou `Could not find 'bundler'`.
**Causa:**
O terminal macOS revertia para o Ruby do sistema (2.6) ao abrir novas abas ou reiniciar, ignorando a versão do projeto (3.4.4).

**Solução:**
Sempre reinicializar o gerenciador de versões (`rbenv`) antes de rodar comandos Ruby.

```bash
eval "$(rbenv init -)"
```

---

## 3. O Mistério do "Canal Inativo" (Webhook Ignorado)

**Sintoma:**

- Webhook recebido com sucesso (HTTP 200).
- Log do Rails: `Inactive WhatsApp channel: unknown - 5561991544165`.
- Nenhuma mensagem aparecia na tela.
  **Causa:**
  Incompatibilidade de formato telefônico:
- **WuzAPI:** Enviava o remetente como `5561991544165` (Com DDI 55).
- **Banco de Dados:** O canal estava cadastrado como `61991544165` (Sem DDI).
  O Chatwoot não conseguia casar os números.

**Solução:**
Atualizar o registro no banco de dados para incluir o DDI `55`.

```ruby
# Comando rodado via Rails Runner ou Console
Channel::Whatsapp.find(ID_DO_CANAL).update(phone_number: '5561991544165')
```

---

## 4. Túnel SSH Instável (Serveo)

**Sintoma:** Mensagens paravam de chegar no Webhook.
**Causa:** O túnel `serveo.net` encerrava ao fechar o terminal, gerando uma NOVA URL ao reiniciar.
**Solução:**
Sempre verificar se o túnel está de pé e se a URL no WuzAPI bate com a URL ativa no terminal.

---

## 🚀 O "Comando Mestre" de Reinicialização

Para reiniciar a aplicação garantindo que **todos** os problemas acima (1 e 2) sejam evitados, use sempre este comando combinado:

```bash
eval "$(rbenv init -)" && export POSTGRES_PORT=5438 && (pkill -f rails || true) && (pkill -f sidekiq || true) && (pkill -f foreman || true) && rm -f tmp/pids/server.pid && bundle exec foreman start -f Procfile.dev
```

**O que ele faz:**

1.  **`eval ...`**: Garante Ruby 3.4.4.
2.  **`export ...`**: Garante Banco de Dados correto (Porta 5438).
3.  **`pkill ...`**: Mata processos velhos/travados.
4.  **`rm ...`**: Remove travas de PID antigas.
5.  **`foreman start`**: Inicia tudo limpo.
