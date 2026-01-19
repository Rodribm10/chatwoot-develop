---
description: padrao jasmine docs
---

## Guia de pensamento para alinhar Jasmine + Daniela Reservas

Sempre que precisar revisar ou ajustar o fluxo de reservas, siga este checklist mental. Ele garante que toda intervenção esteja alinhada com o objetivo macro que você descreveu (contato cordial → ativar Daniela → coleta completa → cálculo do valor por dia → Pix de 50% → confirmação final).

1. **Entenda o contexto final do usuário**

   - O cliente entra com um “bom dia”, “posso reservar?” ou similar.
   - O objetivo é caminhar até uma reserva confirmada com Pix: sem desvios, sem repetição de perguntas.
   - Qualquer erro deve ser interpretado à luz desse fluxo (não como uma exceção isolada).

2. **Priorize o fluxo estruturado, não atalhos “temáticos”**

   - Jasmine deve sempre responder com cordialidade inicial e detectar quando acionar Daniela.
   - Toda ação de reserva (dados do cliente, suíte, data, valor) deve ser comandada por Daniela, informando o cliente do próximo passo.
   - Evite fallback direto do Brain para respostas livres quando o fluxo já está em andamento.

3. **Mantenha estado consistente durante todo o fluxo**

   - O cenário ativo precisa persistir na conversa: `active_scenario_key`, `expires_at`, `active_scenario_state`.
   - O `state` guarda stage, dados coletados (CPF, suíte, data) e resultados de ferramentas (availability, pix).
   - Em cada turno, atualize esse estado e só encerre quando o Pix for gerado ou o cliente disser “cancelar/obrigado”.

4. **Ferramentas obedecem ao roteiro**

   - `check_availability` determina o valor correto conforme a data e o dia da semana (verfica as tabelas).
   - `create_reservation_intent` guarda os dados coletados; jamais pula etapas.
   - `generate_pix` deve receber o valor calculado e aplicar exatamente `valor / 2` quando solicitado (entrada 50%).
   - Se algum passo falhar, o sistema deve comunicar o erro (fallback adequado) e manter o cliente no fluxo, não encerrar com mensagens genéricas como “dificuldades técnicas”.

5. **Fluxo conversacional esperado**

   1. Jasmine responde com cordialidade e confirma a intenção.
   2. Daniela entra pedindo nome/CPF, suíte, data, horário.
   3. Daniela informa valor, explica “pode pagar 50% agora via Pix”.
   4. Daniela chama `generate_pix`, envia o código, explica "copie e cole".
   5. Após cliente avisar “paguei”, Daniela confirma a reserva e encerra o cenário.
   6. Se o cliente desistir ou pedir humano, encerre/limpe sticky e deixe Lucia (Jasmine) responder com fallback apropriado.

6. **Logs e documentação**
   - Sempre que alterar algo, registre nas instruções/prompt das agents (ex: prompt da Daniela deve explicitar o roteiro).
   - Se necessário fazer mudanças pontuais, vincule essas mudanças ao fluxo (não apenas "ajustar o Pix").
   - Use este documento como ponto de referência antes de testar: se você “esquecer”, leia e repita mentalmente o que o Rodrigo quer.

Se precisar de ajuda para transformar isso em tarefas técnicas (migrations, short-circuit, state), é só avisar.

---

## Documento de referência ampliado (fluxo reserva + Pix)

### 1. Objetivo “padrão-ouro”

O sistema deve rodar este fluxo previsível para cada pedido de reserva:

1. Cliente cumprimenta → Jasmine responde educadamente.
2. Cliente manifesta “quero reservar” → Jasmine delega para Daniela.
3. Daniela conduz todo o plano: coleta dados, chama ferramentas (precio/disponibilidade/pix), monta a próxima mensagem.
4. Jasmine publica o texto final no tom oficial (voz única para o cliente).
5. Coleta obrigatória concentrada na Daniela: nome completo, CPF, suíte, data, horário/período.
6. Daniela confirma: “Sua reserva ficou assim… total R$T. Posso gerar o Pix (50%)?”
7. Cliente confirma → Daniela gera Pix de metade do total e instrui “copie e cole no seu banco”.
8. Após o cliente avisar “paguei”, Daniela confirma o pagamento e informa que a reserva está confirmada.

Sucesso significa que a reserva segue esse roteiro, com Pix gerado/confirmado e sem decisões aleatórias.

### 2. Papéis e responsabilidades

- **Jasmine (“interface única”)**: cumprimenta, decide se deve delegar, publica as respostas da Daniela e mantém o tom padrão. Nunca responde diretamente sobre reservas, preços ou Pix — sempre delega ao subagente adequado.
- **Daniela (“motor transacional”)**: permanece na camada interna. Recebe contexto, coleta dados, valida, chama `check_availability`, `create_reservation_intent`, `generate_pix`, constrói o `mensagem_para_cliente` e retorna também o `estado_atualizado` e as ações requisitadas.

### 3. Regras de comportamento

- Tom educado e uniforme mesmo quando a resposta vem da Daniela.
- Não inventar preços ou disponibilidade: os valores derivam exclusivamente de `check_availability` e do histórico fornecido.
- Sempre perguntar “posso gerar o Pix?” antes de chamar `generate_pix`.
- Não sair do fluxo: enquanto o sticky scenario estiver ativo, o Brain não deve responder com mensagens independentes ou fallback.

### 4. Arquitetura mínima para consistência

A) **Sticky “modo reserva”** – Conversa persiste: `active_scenario_key`, `active_scenario_expires_at`, `active_scenario_state`. Uma vez ativado por Daniela, todas as próximas mensagens vão direto para ela até conclusão/cancelamento.
B) **Estado mínimo persistido** – `active_scenario_state` deve conter:

- `stage` (p.ex. collecting_data, quoting, waiting_payment)
- `collected` (nome, CPF, suíte, data, horário)
- `last_quote` (preço, disponibilidade, dia/turno)
- `pix_status` (pending/paid/confirmed)
  Isso evita perda de memória entre turnos e mantém o fluxo determinístico.

### 5. Tratamento de erros (visão macro)

Quando surgir um erro (resposta desalinhada, ferramenta falhando, handoff disparado), trace o contexto:

1. Qual stage estava ativo?
2. Jasmine desviou e respondeu sozinha?
3. Daniela repetiu perguntas ou perdeu dados?
4. Qual tool falhou ou retornou inválido?
   Corrija sempre com base nesse fluxo padrão — não apenas “ajuste a frase”, mas reforce o sticky/state/sequence.

### 6. Como trabalhamos na prática

Sempre que você me mostrar um erro, envie:

1. Mensagem do cliente.
2. Resposta publicada pela Jasmine.
3. Trecho do log relevante (20–60 linhas) indicando decisão/tool.

Com isso eu devolvo:

- Onde travar o sticky/state.
- Qual prompt deve ser ajustado.
- Qual ferramenta/filtro precisa validar o valor ou o Pix.

### 7. Regra mestre

“Daniela é o cérebro do fluxo transacional e retorna o texto pronto; Jasmine é a única voz que publica para o cliente no tom oficial. O sistema deve manter estado e sticky para que o fluxo seja determinístico.”

---

## 🎯 Simulação de atendimento ideal – experiência perfeita de reserva

**Cliente:**  
Boa noite

**Jasmine:**  
Boa noite! 😊  
Seja bem-vindo. Como posso te ajudar hoje?

**Cliente:**  
Gostaria de fazer uma reserva

**Jasmine:**  
Perfeito! Vou te ajudar com isso 😊  
Para darmos continuidade à sua reserva, poderia me informar, por favor, seu nome completo e CPF?

**Cliente:**  
João Pedro da Silva, CPF 123.456.789-00

**Jasmine:**  
Obrigada, João 😊  
Agora me diga, por favor: qual suíte você deseja reservar?

**Cliente:**  
Suíte Luxo

**Jasmine:**  
Ótima escolha! ✨  
Para qual data e horário/período você gostaria da reserva?

**Cliente:**  
Dia 20/02, das 22h às 10h

**Jasmine:**  
Perfeito! Só um instante que vou verificar a disponibilidade e os valores para você 😊

(internamente: Daniela consulta disponibilidade e preço)

**Jasmine:**  
Prontinho! 😊  
Sua reserva ficou assim:

• Suíte: Luxo  
• Data: 20/02  
• Horário: das 22h às 10h  
• Valor total: R$ 300,00

Para confirmar a reserva, é necessário o pagamento de 50% (R$ 150,00).  
Posso gerar o Pix para você agora?

**Cliente:**  
Pode sim

**Jasmine:**  
Perfeito 😊  
Segue abaixo o Pix para pagamento da entrada:

💰 Valor: R$ 150,00  
📌 Chave Pix: 123e4567-e89b-12d3-a456-426614174000

👉 Basta copiar a chave Pix, colar no aplicativo do seu banco e realizar o pagamento.  
Assim que pagar, me avise por aqui para que eu confirme sua reserva, tudo bem?

**Cliente:**  
Pronto, acabei de pagar

**Jasmine:**  
Só um instante que vou confirmar o pagamento para você 😊

(internamente: Daniela confirma pagamento)

**Jasmine:**  
Pagamento confirmado com sucesso! ✅

Sua reserva está confirmada 🎉  
Resumo final:

• Suíte: Luxo  
• Data: 20/02  
• Horário: das 22h às 10h  
• Entrada paga: R$ 150,00

Qualquer dúvida ou se precisar de algo mais, é só me chamar.  
Será um prazer te receber! 😊✨

### 🔑 Por que essa experiência é boa

- Linguagem humana e educada
- Um pedido por vez (sem sobrecarregar)
- Confirmação clara antes da cobrança
- Segurança no Pix
- Encerramento com sensação de sucesso

Se quiser, nos próximos passos posso:

- marcar onde entra cada stage,
- transformar isso em script técnico para os prompts da Daniela/Jasmine, ou
- criar a versão “anti-confusão” (quando o cliente muda de assunto ou responde errado).

### 💬 Instrução extra: Pix Copia e Cola completo

Quando o GeneratePixTool retornar o código, **garanta que o bloco de código contenha a string inteira**, iniciando em `0002010...` e terminando no checksum `...6304XXXX`. Esse é o valor que o cliente precisa colar no banco; qualquer corte causa “Pix inválido”. Copie exatamente o `raw_payload` do tool (ou o `formatted_message` caso já contenha a string completa) e anexe no bloco antes de enviar. Nada deve ser truncado ou substituído pela Jasmine depois de a mensagem sair.
