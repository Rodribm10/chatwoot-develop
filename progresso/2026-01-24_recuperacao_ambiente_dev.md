# Recuperação do Ambiente de Desenvolvimento (24/01/2026)

## Contexto

O usuário relatou perda de dados ("app novo")- [x] Debug/Fix Reservations Page (`/public/.../reservas`) <!-- id: 14 -->após tentar rodar o ambiente. Houve uma confusão entre diretórios de projeto (`chatwoot-main` vs `chatwoot-develop`) e conflitos de banco de dados local vs Docker.

## Problemas Identificados

1.  **Conflito de Porta Postgres:** Porta `5432` já em uso no host, impedindo start do Docker.
2.  **Diretório Incorreto:** O terminal estava rodando em `chatwoot-main` (código limpo/antigo) em vez de `chatwoot-develop` (código com features customizadas do cliente).
3.  **Banco de Dados Inseguro:** Container antigo PostgreSQL 15 não suportava extensão `vector` necessária para novas features de IA.
4.  **Perda Aparente de Dados:** Ao resetar o banco do `main`, o usuário "perdeu" acesso.

## Solução Aplicada

### 1. Infraestrutura de Banco de Dados

- **Nova Porta:** Configurado `chatwoot-develop` para usar Postgres na porta **5433** (`POSTGRES_PORT=5433` no .env e docker-compose).
- **Migração de Dados:**
  - Backup realizado do container antigo (`chatwoot-develop-postgres-1` -> banco `chatwoot_dev`).
  - Restaurado no novo container (`chatwoot-main-postgres-1` -> banco `chatwoot_dev`) rodando imagem compatível (`pgvector/pgvector:pg16`).
  - Executado `db:prepare` e `db:migrate` para alinhar schemas.

### 2. Correção de Código (Codebase)

- **Switch de Diretório:** Alterado execução para `/Users/user/Dev/Produtos/Chatwoot/chatwoot-develop`.
- **Dependências:** Ajustado `package.json` para aceitar Node >= 20 e pnpm >= 8 (compatível com ambiente local).
- **Ambiente:** Atualizado `.env` do `develop` para apontar corretamente para o novo banco na porta 5433.

### 3. Acesso

- Usuário `rodrigobm10@gmail.com` verificado e senha redefinida/confirmada para `Nicodemos1@@1`.

### 4. Correção Frontend "Reservas"

- **Problema:** A página de reservas estava "bugada" (branca/erro) porque o ponto de entrada `captain_booking.js` tentava carregar um arquivo Vue inexistente (`App.vue`).
- **Causa:** A migração de código para React (`captain_booking_app`) não atualizou o entrypoint principal.
- **Solução:** Substituído `app/javascript/entrypoints/captain_booking.js` por `captain_booking.tsx`, configurado para montar corretamente a aplicação React localizada em `enterprise/app/javascript/captain_booking_app/App.tsx`.

### 7. Correção Carregamento de Unidades (Mismatch de Tipo)

- **Problema:** O dropdown "Unidade" mostrava "Nenhuma unidade para esta marca" mesmo com marcas da rede cadastradas.
- **Causa:** Incompatibilidade entre o TypeScript (`brandId`) e a resposta da API (`captain_brand_id`). O filtro no frontend falhava (`undefined !== brand.id`).
- **Solução:** Atualizado `types.ts` e `App.tsx` para usar `captain_brand_id`, alinhando com o snake_case do Rails.

## Como Validar

1.  Acessar `http://localhost:3000`.
2.  Logar com `rodrigobm10@gmail.com`.
3.  Verificar se o fundo está Azul e o botão Admin sumiu.
4.  Verificar menu "Reservas" na sidebar.
5.  Acessar a página de reservas pública e verificar se o formulário carrega.
6.  Atualizar a página.
7.  Selecionar "Hotel 1001 Noites".
8.  O dropdown "Unidade" DEVE listar "Prime Águas Claras" e "Unidade Matriz".

### 8. Sincronização Categorias da Unidade (System Data)

- **Problema:** As categorias exibidas ("Premium", "Master", etc.) eram genéricas e não as cadastradas no admin ("Stilo", "Alexa", etc.).
- **Causa:** No passo 5, popularam-se dados fictícios. O sistema real armazena isso na tabela de Marca (`brands`).
- **Solução:** Rodado script para copiar as categorias reais da `Brand` para a `Unit` no banco de dados.

## Como Validar

1.  Na página de reservas, selecionar "Hotel 1001 Noites Prime".
2.  Selecionar unidade "Prime Águas Claras".
3.  O dropdown "Categoria" deve mostrar: **Stilo, Alexa, Spa-Hidromassagem**.

### 9. Correção Tabela de Preços (Cálculo Zerado)

- **Problema:** Ao selecionar data/hora, o "Valor Total da Reserva" não aparecia ou ficava zerado.
- **Causa:** As novas categorias (Stilo, Alexa, etc.) não tinham tabela de preço cadastrada no banco (`captain_pricings`).
- **Solução:** Executado script para gerar tabela de preços padrão (R$ 80,00 base) para todas as categorias e durações da marca "Hotel 1001 Noites Prime".

## Como Validar

1.  Selecionar "Prime Águas Claras".
2.  Categoria "Stilo".
3.  Permanência "3hrs".
4.  Data Hoje + Horário atual.
5.  **Verificar:** Card de preço deve aparecer "Valor Total da Reserva: R$ 80,00" (ou similar).

## Próximos Passos (Recomendação)

- Manter uso exclusivo da pasta `chatwoot-develop`.
- Não alterar porta do Postgres sem revisar `docker-compose.yaml`.
