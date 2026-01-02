# Implementation Plan (V1) — Jasmine Tools (HTTP)

Adicionar suporte a ferramentas HTTP configuráveis por inbox no Jasmine AI.

## 1. Modelagem de Dados

Optamos pela **Opção A (Tabela Dedicada)** para garantir integridade, facilidade de query e segurança (criptografia de tokens).

### Schema

Tabela: `jasmine_tool_configs`

| Coluna            | Tipo     | Detalhes                                       |
| ----------------- | -------- | ---------------------------------------------- |
| `id`              | uuid     | Primary Key                                    |
| `account_id`      | integer  | FK -> accounts                                 |
| `inbox_id`        | integer  | FK -> inboxes                                  |
| `tool_key`        | string   | Identificador (ex: "status_suites"). Indexado. |
| `is_enabled`      | boolean  | Default: false                                 |
| `plug_play_id`    | string   | ID do cliente na API PlugPlay                  |
| `plug_play_token` | text     | Token criptografado (Rails encrypted)          |
| `created_at`      | datetime |                                                |
| `updated_at`      | datetime |                                                |

**Index Único:** `[:account_id, :inbox_id, :tool_key]`

## 2. Backend Implementation

### A. Constantes das Ferramentas

Definir as ferramentas fixas no sistema (ex: em um módulo ou constante).

```ruby
module Jasmine::Tools
  DEFINITIONS = {
    'status_suites' => {
      name: 'Status das Suítes',
      method: :get,
      url: 'https://oxpi.com.br/api/PlugPlay/api/SuitesStatus',
      description: 'Verifica o status atual das suítes.'
    },
    'listar_reservas' => {
      name: 'Listar Reservas',
      method: :get,
      url: 'https://oxpi.com.br/api/PlugPlay/api/Reserva?exibicao=0&pagina=1',
      description: 'Lista as reservas ativas.'
    },
    'categoria_disponibilidade' => {
      name: 'Disponibilidade por Categoria',
      method: :get,
      url: 'https://oxpi.com.br/api/PlugPlay/api/CategoriaDisponibilidade',
      description: 'Verifica disponibilidade de categorias.'
    }
  }.freeze
end
```

### B. Model: `Jasmine::ToolConfig`

- `belongs_to :account`
- `belongs_to :inbox`
- `encrypts :plug_play_token` (Rails 7 encryption ou attr_encrypted)
- Validations: `presence` of ID/Token if `is_enabled`.

### C. Service: `Jasmine::ToolRunner`

Responsável por executar a chamada HTTP segura.

- **Input:** `tool_key`, `inbox`, `account`.
- **Logic:**
  1. Busca config no DB.
  2. Se não existir ou disabled, erro.
  3. Monta request com headers:
     - `PLUG-PLAY-ID`: config.plug_play_id
     - `PLUG-PLAY-TOKEN`: config.plug_play_token
  4. timeout: 8s.
  5. Retorna Hash com `success`, `status`, `body` (preview), `duration`.
- **Security:** `rescue` de exceções com logs **sanitizados** (nunca logar token).

### D. Controller: `Api::V1::Accounts::Jasmine::ToolsController`

| Método   | Endpoint                                 | Descrição                                                                              |
| -------- | ---------------------------------------- | -------------------------------------------------------------------------------------- |
| `index`  | `GET /inboxes/:inbox_id/tools`           | Retorna lista mesclada (DEFINITIONS + configs salvas). Tokens vem mascarados (`****`). |
| `update` | `PATCH /inboxes/:inbox_id/tools/:id`     | Atualiza config (ID, Token, Enabled). Aceita `tool_key` para criar se não existir.     |
| `test`   | `POST /inboxes/:inbox_id/tools/:id/test` | Executa `ToolRunner` e retorna resultado. Rate limit de 10/min.                        |

## 3. Frontend Implementation

### A. API Client (`jasmine.js`)

- `fetchTools(inboxId)`
- `updateTool(inboxId, toolKey, data)`
- `testTool(inboxId, toolKey)`

### B. Componentes Vue

1.  **`JasmineToolsTab.vue`**

    - Lista de cards.
    - Itera sobre `DEFINITIONS` (vindo do backend).

2.  **`JasmineToolCard.vue`**
    - Props: `tool` (definição + config).
    - State: `isEditing`, `isTesting`.
    - UI:
      - Header: Nome, Método (Badge), URL (readonly, text-xs truncated).
      - Form (Edit Mode): Input ID, Input Token (Show/Hide).
      - Footer: Toggle Switch, Botão "Testar Conexão".
    - Teste UI:
      - Mostra spinner.
      - Sucesso: Badge Verde + Tempo + Preview JSON.
      - Erro: Badge Vermelho + Mensagem.

## 4. Segurança & Testes

### Segurança

- **Logs:** Filtro de parâmetros no Rails (`config.filter_parameters += [:plug_play_token]`).
- **Response:** Tokens retornados no `index` devem ser mascarados se existirem. O frontend só envia token novo se o usuário editar.

### Testes

- **Model Spec:** Validar unicidade e criptografia.
- **Service Spec:** Mock de HTTP requests (WebMock), validar headers.
- **Request Spec:** Testar fluxo de update e listagem, garantindo isolamento de conta.

## 5. Passo a Passo de Execução

1.  **Migration:** Criar tabela `jasmine_tool_configs`.
2.  **Backend Core:** Criar Model `Jasmine::ToolConfig` e Configuração de Criptografia.
3.  **Service:** Implementar `Jasmine::ToolRunner` com HTTP client seguro.
4.  **API:** Implementar `ToolsController` e rotas.
5.  **Frontend:** Criar `JasmineToolsTab` e `JasmineToolCard`.
6.  **Integração:** Adicionar aba na `JasmineInboxDashboard.vue`.
7.  **Verificação:** Testar fluxo completo (Salvar -> Testar -> Ver Logs).
