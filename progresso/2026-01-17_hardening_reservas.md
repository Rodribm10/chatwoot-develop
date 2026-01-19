# Manifesto de Hardening: Arquitetura de Reservas & Pix (Jasmine/Daniela)
**Data:** 17/01/2026
**Status:** Estável (Com detalhes finos de valor em análise)

## 1. O Contexto
O sistema de reservas via WhatsApp (Jasmine -> Daniela) enfrentava instabilidades críticas que comprometiam a confiança do usuário:
- **Alucinação de Suíte:** A IA inventava ou persistia na suíte errada (ex: "Alexa") mesmo quando o usuário pedia outra ("Stilo"), ignorando o contexto recente.
- **Loop de Confirmação:** O agente entrava em loop perguntando "Posso reservar?" infinitamente.
- **Pix Quebrado:** O código Copia e Cola chegava cortado ou mal formatado, impossibilitando o pagamento.
- **Datas Erradas:** "Amanhã às 21h" era interpretado como "Hoje às 21h", gerando erro de disponibilidade.

## 2. Soluções Implementadas (A Muralha de Defesa)

### 🛡️ 1. Anti-Alucinação (O "Muro de Berlim")
Alteramos a lógica de leitura de histórico nas ferramentas `CheckAvailabilityTool` e `CreateReservationIntentTool`.
- **Como funciona:** O sistema varre as mensagens do usuário **de trás para frente**. Ao encontrar a palavra-chave **"Reiniciar"** (ou "Resetar"), ele **PARA** a leitura.
- **Resultado:** Qualquer suíte mencionada antes do reset se torna invisível para a ferramenta de validação. Isso impede que "fantasmas" de conversas passadas contaminem a nova reserva.
- **Aliases:** Adicionamos suporte a apelidos (ex: "hidro" = "Hidromassagem") para evitar bloqueios indevidos.

### 📅 2. Resolução de Data Inteligente
Corrigimos o bug onde fornecer um horário (`check_in_at`) sobrescrevia a data (`date`).
- **Nova Lógica:** Se o usuário diz "Amanhã" e depois "21:00", o sistema combina as duas informações (`Base Date` + `Time`), garantindo que a reserva caia no dia correto.

### 🔁 3. Check de Idempotência & Anti-Loop
Implementamos uma trava na `CreateReservationIntentTool`.
- **Lógica:** Antes de criar uma reserva, verificamos se já existe um "draft" idêntico (mesma suíte/preço) criado nos últimos 5 minutos.
- **Ação:** Se existir, a ferramenta **BLOQUEIA** a criação e retorna uma instrução imperativa: *"Reserva JÁ EXISTE. Pare de criar e CHAME O PIX AGORA."*
- **Resultado:** Fim dos loops de "Reserva confirmada" repetidos.

### 💸 4. Pix Robusto & Formatado
- **Formatação:** O `GeneratePixTool` agora retorna o código dentro de um bloco Markdown triplo (` ``` `), garantindo que o WhatsApp exiba como código monoespaçado (fácil de copiar).
- **Reconstrução (Frankenstein):** Se a API do Banco Inter retornar um código cortado (iniciando com `/spi/...`), o sistema detecta e **anexa automaticamente** o cabeçalho padrão (`000201...bancointer.com.br`), salvando o pagamento.
- **Log de Caixa Preta:** Adicionamos log do JSON bruto do banco para auditoria.

### 💰 5. Trava Global de Preço
- **Segurança:** A ferramenta de criação agora compara o preço da reserva com a **última cotação de disponibilidade** feita na conversa.
- **Resultado:** Se a IA tentar cobrar R$ 80,00 por uma suíte que foi cotada a R$ 60,00, o sistema bloqueia a transação.

## 3. Estado Atual & Próximos Passos
O fluxo "Happy Path" (Reiniciar -> Escolher -> Reservar -> Pix) está funcional e seguro.

**Ponto de Atenção (Investigação Ativa):**
- Houve um relato de divergência no valor final do Pix (Texto diz R$ 40,00, Pix cobra R$ 60,00).
- **Ação:** Adicionamos logs explícitos do ID da reserva no `GeneratePixTool` para rastrear se o sistema está pegando uma reserva "zumbi" antiga.

---
**Arquivos Chave Alterados:**
- `enterprise/app/services/captain/tools/check_availability_tool.rb`
- `enterprise/app/services/captain/tools/create_reservation_intent_tool.rb`
- `enterprise/app/services/captain/tools/generate_pix_tool.rb`
- `enterprise/app/services/captain/inter/cob_service.rb`
