# Runbook - Captain Tools, Pix e Daniela (blindagem)

## Objetivo
Documentar o estado atual do fluxo de reservas/Pix e das ferramentas do Captain para evitar regressao quando houver novas mudancas.

## Escopo
- Ferramentas do Captain (tools) usadas pela Jasmine/Daniela.
- Geracao de Pix com expiracao de 1h e reemissao.
- Exposicao das ferramentas na UI (poderes/capacidades) e fallback por ferramenta.

## Principais mudancas feitas
1) Pix com expiracao e reemissao
- Pix expira em 1 hora.
- Se houver Pix pendente e expirado, gera novo Pix.
- Se ainda valido, reenvia o Pix existente.
- Arquivos:
  - enterprise/app/models/captain/pix_charge.rb
  - enterprise/app/services/captain/inter/cob_service.rb
  - enterprise/app/services/captain/tools/generate_pix_tool.rb
  - enterprise/lib/captain/tools/scenario_delegator_tool.rb

2) Ferramentas do Captain listadas na UI
- list_reservations adicionada ao catalogo de tools.
- Ferramentas com configuracao local (nao webhook) aparecem sem bloco de configuracao.
- faq_lookup continua visivel, mas sem toggle de ligar/desligar.
- Arquivos:
  - config/agents/tools.yml
  - enterprise/app/services/captain/tools/definitions.rb
  - app/javascript/dashboard/routes/dashboard/captain/assistants/tools/Index.vue

3) Fallback personalizado por ferramenta
- Cada tool pode ter fallback_message opcional.
- Se tool falhar e houver fallback, resposta usa esse texto.
- Excecoes sem fallback custom: faq_lookup, react_to_message.
- Arquivos:
  - db/migrate/20260116000000_add_fallback_message_to_captain_tool_configs.rb
  - enterprise/app/controllers/api/v1/accounts/captain/tools_controller.rb
  - enterprise/app/services/captain/tools/tool_runner.rb
  - enterprise/app/services/captain/llm/assistant_chat_service.rb

4) Correcoes de schema das tools (evitar erro type)
- RubyLLM espera parametros como RubyLLM::Parameter.
- BaseTool converte schema JSON em parametros.
- JasmineBrain imprime schema correto no prompt.
- Arquivos:
  - enterprise/app/services/captain/tools/base_tool.rb
  - enterprise/app/services/captain/tools/check_availability_tool.rb
  - enterprise/app/services/captain/tools/create_reservation_intent_tool.rb
  - enterprise/app/services/captain/llm/jasmine_brain.rb

## Sintomas conhecidos quando quebra
- Jasmine responde "Desculpe, estou com dificuldades tecnicas..." apos um simples "Ola".
- Erro no log: undefined method 'type' for an instance of String.
- Causa tipica: tool parameters em formato incorreto (schema JSON cru).

## Testes rapidos (smoke)
1) Saudacao simples
- Mensagem: "Ola"
- Esperado: resposta normal da Jasmine (sem erro tecnico).

2) Reserva com Pix novo
- Mensagem: "Quero reservar a suite Stilo dia 20/01 as 14h."
- Esperado: consulta disponibilidade, cria intencao, pede CPF se nao houver, gera Pix novo.

3) Pix expirado
- Repetir pedido apos >1h.
- Esperado: "Pix expirado. Gerando um novo agora." e Pix novo.

4) Consultar reservas
- Daniela deve poder chamar listar reservas quando cliente perguntar "em nome de quem".

## Comandos de log curtos
- Erro de tool schema:
  rg -n "undefined method 'type'" log/development.log | tail -n 5

- Falha de tools do Captain:
  rg -n "ScenarioDelegatorTool|LLM Error" log/development.log | tail -n 20

- Execucao das ferramentas de reserva/Pix:
  rg -n "CreateReservationIntentTool|GeneratePixTool|CheckAvailabilityTool" log/tool_debug.log | tail -n 20

## Observacoes importantes
- Nao alterar formato de tool parameters sem validar com RubyLLM::Parameter.
- Se adicionar nova tool, usar BaseTool e preferir tool_parameters_schema.
- Sempre reiniciar Rails apos mudar tools, schema ou defs.

## Responsavel por revisao
- Antes de qualquer mudanca: rodar os testes rapidos e verificar logs curtos.
