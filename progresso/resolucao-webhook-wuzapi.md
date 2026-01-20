# Resolução: Falha no Recebimento de Webhooks Wuzapi

## Contexto

Mensagens enviadas para o número WhatsApp não estavam chegando na caixa de entrada do Chatwoot no ambiente local, apesar de mensagens de saída funcionarem.

## Diagnóstico

1.  **Backend (Controller)**: O `Webhooks::WuzapiController` existia mas o método `process_payload` estava vazio. Ele recebia o webhook, retornava 200 OK, mas não fazia nada.
2.  **Ambiente (Túnel)**: O comando `make run` inicia apenas o servidor Rails/Sidekiq, sem o túnel Ngrok necessário para expor o localhost para a internet (Wuzapi).
3.  **Segurança**: O ID da Inbox usado nos testes iniciais (3) era diferente do ID do canal para o qual o webhook estava sendo enviado, causando confusão inicial.

## Solução Técnica

1.  **Implementação do Controller**:
    Conectamos o controller ao serviço existente:

    ```ruby
    # app/controllers/webhooks/wuzapi_controller.rb
    def process_payload
      Whatsapp::IncomingMessageWuzapiService.new(inbox: @inbox, params: params.to_unsafe_hash).perform
      head :ok
    rescue StandardError => e
      Rails.logger.error e
      head :internal_server_error
    end
    ```

2.  **Fluxo de Execução**:
    Padronizado o uso de `make force_run_tunnel` para garantir que o Ngrok suba junto com a aplicação.

## Validação

- Teste simulado via `curl` confirmou criação de mensagem no banco.
- Teste real ("Teste 123") confirmado pelo usuário e validado nos logs com resposta automática do Agente ("Olá! Como posso ajudar...").

## Arquivos Alterados

- `app/controllers/webhooks/wuzapi_controller.rb`
- `task.md`, `walkthrough.md` (Documentação)

# Implementação de Presença Simulada (Typing Indicator) e Delay Humanizado

## Contexto e Objetivo

O objetivo era implementar uma experiência de chat mais "humana", onde o bot exibe o status "digitando..." (typing) enquanto processa a resposta e durante um período de delay artificial (humanized delay), antes de enviar a mensagem final.

## Mecanismo de Presença Simulada

O comportamento "humano" é alcançado mantendo o indicador de digitação ativo durante todo o ciclo de geração da resposta:

1.  **Início do Processamento**: O Job (`ResponseBuilderJob`) ativa o status `typing_on`.
2.  **Geração da IA**: O LLM processa a resposta (indicador continua ativo).
3.  **Delay Humanizado**: Um delay calculado (baseado no tamanho da resposta) é executado.
    - _Crítico_: O indicador deve permanecer ativo durante este `sleep`.
4.  **Finalização**: O status é alterado para `typing_off` e a mensagem é enviada imediatamente em seguida.

## Diagnóstico e Correções

Para que este fluxo funcionasse no Wuzapi, corrigimos os seguintes pontos:

1.  **Sincronia do Delay (Correção de UX)**:

    - **Problema**: O código original desligava o indicador (`typing_off`) _antes_ de entrar no `humanized_delay`. Isso causava um "silêncio visual" (sem indicador) de ~5 segundos antes da mensagem aparecer.
    - **Solução**: Movemos a chamada de `typing_off` para **após** a execução do delay.

2.  **Incompatibilidade de Status ("Bug Raiz")**:

    - **Problema**: A aplicação enviava o status simplificado `'on'`, mas o adaptador do Wuzapi esperava estritamente a string `'typing_on'`. Isso fazia o código falhar silenciosamente e enviar `'paused'`.
    - **Solução**: O adaptador (`WuzapiService`) foi atualizado para aceitar tanto `'on'` quanto `'typing_on'`.

3.  **Formato do JID (Protocolo WhatsApp)**:

    - **Problema**: O envio de presença falhava se o número não tivesse o sufixo correto.
    - **Solução**: Forçamos a formatação `<numero>@s.whatsapp.net` no envio para a API do Wuzapi.

4.  **Crash na Validação de Webhook (Entrada)**:
    - **Problema**: Webhooks de presença contendo IDs internos do WhatsApp (`@lid`) quebravam a validação de telefone da aplicação.
    - **Solução**: O parser foi blindado para ignorar IDs inválidos sem travar o processamento.

## Arquivos Chave Alterados

- `enterprise/app/jobs/captain/conversation/response_builder_job.rb`: Ajuste na ordem do `humanized_delay`.
- `app/services/whatsapp/providers/wuzapi_service.rb`: Suporte a status `'on'` e formatação JID.
- `app/services/whatsapp/providers/wuzapi/payload_parser.rb`: Tratamento de IDs inválidos.

## Como Validar

1.  Envie uma mensagem para o bot.
2.  Observe que o status "digitando..." aparece quase imediatamente.
3.  Note que o status **persiste** por alguns segundos (durante o delay).
4.  A mensagem chega assim que o status some.
