---
description: Jasmine padrao para reservas
---

# Manifesto de Desenvolvimento: Jasmine & Daniela (Reservas com Pix)

**Data:** 17/01/2026
**Responsável:** Arquiteto de Software (AI)

## 1. Visão Geral e Objetivo

Este documento define o padrão de desenvolvimento e comportamento para a funcionalidade de **Reservas via Chat** no Chatwoot (projeto Chatwoot-Develop). O objetivo final é uma experiência fluida onde a agente principal (**Jasmine**) orquestra o atendimento, delegando a lógica de negócio complexa para a especialista (**Daniela**), sem que o cliente perceba fricção ou "troca de robôs".

## 2. Experiência de Atendimento Ideal (Script de Referência)

_Todo o desenvolvimento deve buscar replicar exatamente este fluxo de interação:_

**Cliente:** "Gostaria de fazer uma reserva"
**Jasmine:** "Perfeito! Vou te ajudar com isso 😊. Para darmos continuidade à sua reserva, poderia me informar, por favor, seu nome completo e CPF?"

**Cliente:** "João Pedro da Silva, CPF 123.456.789-00"
**Jasmine:** "Obrigada, João 😊. Agora me diga, por favor: qual suíte você deseja reservar?"

**Cliente:** "Suíte Luxo"
**Jasmine:** "Ótima escolha! ✨. Para qual data e horário/período você gostaria da reserva?"

**Cliente:** "Dia 20/02, das 22h às 10h"
_(Internamente: Daniela consulta disponibilidade e preço)_
**Jasmine:** "Prontinho! 😊 Sua reserva ficou assim:
• Suíte: Luxo
• Data: 20/02
• Horário: das 22h às 10h
• Valor total: R$ 300,00

Para confirmar a reserva, é necessário o pagamento de 50% antecipado (R$ 150,00).
Posso gerar o Pix para você agora?"

**Cliente:** "Pode sim"
_(Internamente: Daniela gera intenção e Pix)_
**Jasmine:** "Perfeito 😊 Segue abaixo o Pix para pagamento da entrada:
💰 Valor: R$ 150,00
📌 Chave Pix: [Copia e Cola]
👉 Basta copiar a chave Pix, colar no aplicativo do seu banco e realizar o pagamento. Assim que pagar, me avise por aqui para que eu confirme sua reserva, tudo bem?"

**Cliente:** "Pronto, acabei de pagar"
_(Internamente: Daniela confirma pagamento)_
**Jasmine:** "Pagamento confirmado com sucesso! ✅
Sua reserva está confirmada 🎉
Resumo final:
• Suíte: Luxo
• Data: 20/02
• Horário: das 22h às 10h
• Entrada paga: R$ 150,00

Qualquer dúvida ou se precisar de algo mais, é só me chamar. Será um prazer te receber! 😊✨"

## 3. Protocolo de Debugging (Baseado em Tempo)

Para garantir a análise correta dos erros e a correção assertiva:

1.  **Input do Usuário:** O Rodrigo fornecerá o **Horário de Início da Conversa** (Horário de Brasília).
2.  **Conversão e Análise:** O Arquiteto converterá esse horário para o fuso do servidor (UTC/Local) e analisará os logs (`log/tool_debug.log`, `log/brain_debug.log`, `log/development.log`) a partir desse ponto exato.
3.  **Reconstrução:** O Arquiteto reconstruirá o fluxo passo-a-passo (Intenção -> Ferramenta -> Resposta -> Erro).
4.  **Ação de Correção:** O ajuste será feito para corrigir a raiz do problema, garantindo que o fluxo futuro respeite o item 2 (Script de Referência).

## 4. Princípios de Arquitetura (CTO Mode)

### A. Jasmine é a Interface, Daniela é o Cérebro da Reserva

- **O cliente NUNCA fala diretamente com a Daniela.** A Jasmine é a "persona" que fala.
- A Daniela opera como uma _Tool_ ou _Scenario_ avançado que mantém estado.
- A Jasmine repassa a entrada do usuário para a Daniela, que processa a lógica de negócio e devolve instruções ou fatos.
- **Jasmine:** Responsável pela polidez, emojis e formatação final.
- **Daniela:** Responsável pelo fluxo lógico, cálculo de preços (50%) e validação de dados.

### B. O Estado é Sagrado (Stateful)

- Não podemos depender da memória de curto prazo do LLM para dados críticos (CPF, Valor).
- O estado da reserva (etapa atual, dados coletados) deve ser persistido em `conversation.custom_attributes['jasmine_state']`.
- O fluxo é sequencial: Coleta Nome/CPF -> Coleta Suíte/Data -> Check Disponibilidade -> Acordo de Valor -> Pix -> Confirmação.

### C. Postura "Fix It All"

- Não faremos correções pontuais (ex: "arruma esse erro de sintaxe").
- Ao encontrar um erro, analisaremos o **fluxo completo**.
- Se o Pix falhou, verificaremos desde a coleta do CPF até a chamada da API.

## 5. Estrutura Técnica

- **JasmineBrain (`jasmine_brain.rb`):** Detecta intenção de reserva e delega para `Daniela Reservas`.
- **Daniela (`seed_jasmine_hotel_v3.rb`):** Scenario configurado com instruções rigorosas para seguir o script ideal.
- **Tools:**
  - `update_contact`: Salva Nome/CPF.
  - `check_availability`: Calcula preço total.
  - `create_reservation_intent`: Salva 50% do valor como depósito.
  - `generate_pix`: Gera o Pix Cobrança (Inter/Simulado) para o valor do depósito.

---

_Este documento deve ser lido no início de cada sessão de manutenção desta feature para garantir alinhamento._
