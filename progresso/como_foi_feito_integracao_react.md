# Integração React Booking App no Chatwoot

## Objetivo

Portar a aplicação externa de reservas (React/Vite/Supabase) para dentro do Chatwoot, eliminando a dependência do Supabase e centralizando a lógica no backend Rails.

## Arquitetura Implementada

### 1. Banco de Dados (Novas Tabelas)

Foram criadas tabelas para armazenar os dados mestres que antes ficavam no Supabase:

- `captain_brands`: Marcas de hotéis.
- `captain_units`: Unidades (filiais).
- `captain_pricings`: Tabela de preços dinâmica.
- `captain_extras`: Itens adicionais (ex: Decoração, Champanhe).
- `captain_suites`: Mapeamento de categorias de suítes para IDs externos (API hoteleira).
- `captain_reservations`: Tabela principal de reservas (atualizada com campos de integração).

### 2. Backend (Rails)

Novos controllers na namespace `Public::Api::V1::Captain`:

- `MasterDataController`: Retorna um JSON único com todas as marcas, unidades, preços, extras e suítes. Otimizado para o carregamento inicial do App React.
- `ReservationsController`:
  - `POST /create`: Recebe o payload do React, cria a reserva e chama o Webhook N8N (via `CreateService`).
  - `GET /status/:id`: Endpoint para polling de status de pagamento.

**Serviços:**

- `Captain::Reservations::CreateService`: Centraliza a lógica de criação, validação e disparo de gatilhos externos.

### 3. Frontend (React/Vite)

O código React foi movido para `enterprise/app/javascript/captain_booking_app`.

**Principais Mudanças:**

- **Remoção do Supabase**: Todos os serviços (`brandService`, `hotelUnitService`, etc.) foram refatorados para consumir a API do Chatwoot (`/public/api/v1/captain/master_data`).
- **Configuração do Vite**: Criado `vite.captain.config.mts` para compilar o app e outputar em `public/captain/booking/assets`.
- **Estilização**: Configurado `tailwind.config.js` do Chatwoot para incluir os diretórios do novo app e as cores do Shadcn UI definidos em `index.css`.
- **App.tsx**: Adaptado para chamadas assíncronas e payload com IDs relacionais (account_id, brand_id, unit_id).

### 4. Como Compilar e Rodar

**Backend:**

```bash
bundle exec rails db:migrate
```

**Frontend:**

```bash
# Compila o React para arquivos estáticos em public/
npx vite build --config vite.captain.config.mts
```

**Acesso:**
Acesse `/public/reservas` no navegador. O Rails serve o arquivo `index.html.erb` que carrega os assets compilados.

## Próximos Passos

- Implementar webhook real do N8N para atualizar pagamento.
- Criar interface administrativa no Dashboard do Chatwoot para gerenciar Marcas/Preços (atualmente apenas via console ou seed).
