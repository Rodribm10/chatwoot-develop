# Walkthrough - Captain Assistant Enhancements

Nesta etapa, implementamos a infraestrutura para suporte multi-LLM, uma nova interface de Ferramentas (Skills) para os assistentes e a lógica de transbordo humano.

## 🚀 O que mudou?

### 1. Configuração Multi-LLM

Agora é possível configurar o Provedor (OpenAI ou Gemini) e o Modelo específico diretamente nas configurações básicas do Assistente no Chatwoot.

- **Arquivos:** `AssistantBasicSettingsForm.vue`, `AssistantsController.rb`.
- **Benefício:** Flexibilidade para usar modelos mais baratos (Flash) para triagem e modelos potentes para vendas.

### 2. Interface de Ferramentas (Skills)

Criamos uma nova aba "Skills (Tools)" nas configurações do assistente que permite ativar e configurar ferramentas externas.

- **Backend:** Modelo `Captain::ToolConfig`, `Captain::ToolsController`, Rotas aninhadas.
- **Frontend:** `Tools/Index.vue`, Store e API atualizados.
- **Ferramentas Disponíveis:** `status_suites`, `maria_fotos`, `escalar_humano`.

### 3. Transbordo Humano (Handoff)

A ferramenta `escalar_humano` foi integrada ao pipeline de resposta do Captain.

- **Lógica:** Quando o `JasmineBrain` detecta a intenção de falar com um humano, ele dispara a ferramenta.
- **Efeitos Colaterais:**
  - Adição da label `desligar_ia`.
  - Desativação da IA no atributo customizado da conversa.
  - Retorno de `conversation_handoff` para o Chatwoot, fazendo com que o bot seja desatribuído e a equipe notificada.

## 🛠 Como Verificar

### Configuração LLM

1. Acesse as configurações de um Assistente.
2. Altere o provedor para **Gemini** e salve.
3. Verifique se as configurações persistem ao recarregar a página.

### Skills (Tools)

1. Vá para a aba **Skills (Tools)** no menu lateral do Assistente.
2. Ative a ferramenta **Check suite availability**.
3. Insira uma URL de Webhook ou IDs do Plug&Play e saia do campo para salvar (Auto-save no blur).
4. Verifique no banco de dados: `Captain::ToolConfig.last` deve refletir as mudanças.

### Handoff

1. Envie uma mensagem que exija transbordo (ex: "Quero falar com um atendente").
2. O Log do Rails deve mostrar a detecção de intenção e a execução da ferramenta.
3. A conversa deve ser marcada com a label `desligar_ia` e o bot deve parar de responder.

## 📝 Notas Técnicas

- O `ToolRunner` agora busca configurações priorizando o Assistente (`captain_assistant_id`), mantendo compatibilidade com Inboxeslegadas.
- O `AssistantChatService` atua como orquestrador entre o Cerebelo (`JasmineBrain`) e o Corpo (`ToolRunner`).
