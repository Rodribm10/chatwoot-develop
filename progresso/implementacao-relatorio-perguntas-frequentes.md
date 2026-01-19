# Implementação do Relatório de Perguntas Frequentes (Frequent Questions Report)

## Objetivo

Implementar um novo relatório no dashboard do Chatwoot que exiba as perguntas mais frequentes (motivos de contato) clusterizados automaticamente por IA, utilizando os dados extraídos durante a resolução das conversas.

## Contexto

Diferente da funcionalidade de FAQ do Captain AI (que foca em RAG para o assistente responder), este relatório foca em **insights gerenciais**. Ele utiliza o `AutoLabelJob` para extrair uma pergunta canônica e o `ClusterJob` para agrupar essas perguntas em temas comuns.

## Passos Realizados

### Backend

1. **Modelo e Migração**:
   - Criação da tabela `frequent_questions` (`account_id`, `label`, `question_text`, `occurrence_count`, `cluster_date`).
   - Arquivo: `db/migrate/20260119150720_create_frequent_questions.rb`.
   - Modelo: `app/models/frequent_question.rb`.
2. **Associação em Account**:
   - Adicionada associação `has_many :frequent_questions` no modelo `Account` para permitir acesso direto via `Current.account`.
3. **Extração de Dados**:
   - O `AutoLabelJob` (`app/jobs/conversations/auto_label_job.rb`) extrai a dúvida canônica e salva em `conversation.additional_attributes['ai_canonical_question']`.
4. **Processamento de Clusters**:
   - Criação do `Conversations::ClusterJob` (`app/jobs/conversations/cluster_job.rb`) para agrupar as perguntas canônicas e consolidar as contagens.
   - Agendamento diário (00:00 UTC) em `config/schedule.yml`.
5. **API**:
   - Controller: `app/controllers/api/v1/accounts/frequent_questions_controller.rb`.
   - Rota: `/api/v1/accounts/:account_id/frequent_questions`.
   - View: `app/views/api/v1/accounts/frequent_questions/index.json.jbuilder`.

### Frontend

1. **API Client**: `app/javascript/dashboard/api/frequentQuestions.js`.
2. **Traduções**: Adicionadas chaves `FREQUENT_QUESTIONS` em `app/javascript/dashboard/i18n/locale/pt_BR/report.json`.
3. **Componente de UI**: `app/javascript/dashboard/routes/dashboard/settings/reports/FrequentQuestionsIndex.vue` redesenhado com padrão premium (ReportHeader, V4Button, estados de loading, sombras suaves).
4. **Roteamento**: Adicionada rota `frequent_questions` em `app/javascript/dashboard/routes/dashboard/settings/reports/reports.routes.js`.
5. **Navegação**: Link adicionado ao Sidebar em `app/javascript/dashboard/components-next/sidebar/Sidebar.vue`.

## Como Validar ou Reverter

### Validação

1. Navegue até **Relatórios** > **Perguntas Frequentes**.
2. Verifique se a lista de clusters é exibida corretamente.
3. Para testar o processamento, rode: `bundle exec rails runner script/generate_test_questions.rb`.

### Reversão

1. Remover a rota em `config/routes.rb`.
2. Reverter os arquivos de frontend alterados.
3. Dropar a tabela: `bundle exec rails db:rollback`.

## Observações Técnicas (Riscos e Decisões)

- **Risco de Performance**: O agrupamento via LLM pode ser caro. O `ClusterJob` foi agendado diariamente para mitigar custo e processamento em tempo real.
- **Diferenciação**: Explicitamente separado do Captain FAQ para evitar poluição da base de conhecimento do assistente com dados puramente analíticos.
- **Blocker Externo**: Houve um erro de `TypeError` na gem `annotaterb` durante as migrações no ambiente (problema preexistente), mas a tabela foi criada com sucesso e a execução pôde prosseguir.
