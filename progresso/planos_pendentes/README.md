# Planos pendentes

## Captain: usar tools sem JasmineBrain (status_suites)

Objetivo: deixar o proprio Captain decidir quando chamar tools (ex.: status_suites), sem classificador separado (JasmineBrain).

Proposta:
- Remover o bypass do JasmineBrain no fluxo de resposta.
- Expor a tool status_suites como tool disponivel diretamente ao Captain.
- Atualizar o prompt fixo para:
  - chamar status_suites somente quando o usuario perguntar sobre disponibilidade de suites;
  - nao chamar para outros assuntos.
- Manter logs para auditar quando a tool foi acionada e o resultado usado.

Arquivos envolvidos:
- enterprise/app/services/captain/llm/assistant_chat_service.rb
- enterprise/app/services/captain/llm/system_prompts_service.rb
- enterprise/app/services/captain/tools/definitions.rb
- enterprise/app/services/captain/tools/tool_runner.rb

Aceite:
- Pergunta sobre disponibilidade chama status_suites.
- Pergunta fora do tema nao chama tool.
- Resposta usa dados retornados pela tool.
- Log explicito de uso da tool.
