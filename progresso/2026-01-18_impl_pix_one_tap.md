# Implementação Pix One-Tap (Link Seguro)

Data: 2026-01-18
Responsável: Antigravity

## Objetivo

Resolver o problema de usabilidade no WhatsApp onde o código "Pix Copia e Cola" quebrava a formatação ou não era facilmente copiável, criando uma experiência de pagamento fluida ("One-Tap").

## Mudanças Realizadas

### 1. Backend (Rails)

- **Rota:** Criada rota curta `/r/:token` (`config/routes.rb`) para URLs amigáveis.
- **Controller:** Criado `Public::Api::V1::Captain::PaymentsController` para resolver o token SGID e renderizar a página.
- **Segurança:** Uso de `GlobalID::Locator.locate_signed` com tokens que expiram em 2 horas (alinhado ao vencimento do Pix).
- **Model:** Adicionado helper `original_value` em `Captain::PixCharge` para facilitar o acesso ao valor da reserva.

### 2. Frontend (View)

- **Arquivo:** `app/views/public/api/v1/captain/payments/show.html.erb`.
- **Design:** Interface Mobile-First limpa usando TailwindCSS.
- **Funcionalidade:**
  - Botão "COPIAR CÓDIGO PIX" com feedback visual.
  - Script de fallback para garantir funcionamento em HTTP/Localhost e Webviews (onde `navigator.clipboard` é bloqueado).
  - Exibição de Nome da Unidade e Valor Formatado.

### 3. Integração (Captain AI)

- **Tool:** `GeneratePixTool` atualizada para:
  - Gerar o token assinado (SGID).
  - Montar a URL (`/r/:token`).
  - Enviar mensagem instrutiva ("Clique no link...") em vez do código bruto.
  - Sanitizar `0.0.0.0` para `127.0.0.1` em ambiente de desenvolvimento.
  - Instrução explícita anti-Markdown para a LLM não quebrar o link no WhatsApp.

### 4. Correções (Fixes)

- Correção de `NoMethodError` na view.
- Tratamento de erro se o token for inválido ou expirado.
- Adição de `purpose: :pix_payment` no SGID para evitar reuso de tokens de outros contextos.

## Como Validar

1. Gerar um Pix via Jasmine (`GeneratePixTool`).
2. Clicar no link recebido.
3. Verificar se o nome da unidade e valor conferem.
4. Clicar em Copiar e validar se o hash Pix está na área de transferência.

## Próximos Passos Sugeridos

- Monitorar conversão de pagamentos com o novo fluxo.
- Avaliar necessidade de fallback para envio de PDF/TXT caso o cliente solicite explicitamente.
