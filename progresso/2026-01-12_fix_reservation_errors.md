# Solução de Erros na Criação de Reservas (12/01/2026)

Este documento registra os problemas encontrados e as soluções aplicadas durante a confirmação de reservas no fluxo público (`/public/accounts/:id/reservas`).

## 1. Erro 500: `undefined local variable or method 'reservation_params'`

**Sintoma:**
Ao enviar o formulário de reserva, a API retornava erro 500.

**Causa:**
O controlador `Public::Api::V1::Captain::ReservationsController` estava tentando usar métodos auxiliares (`reservation_params` e `unit`) que não estavam definidos nessa classe (provavelmente foram copiados/referenciados da versão administrativa, mas não implementados).

**Solução:**
Foram adicionados os métodos privados necessários no controlador:

```ruby
def unit
  @unit ||= ::Captain::Unit.find(params[:unit_id])
end

def reservation_params
  params.permit(
    :brand_id, :unit_id, :contact_name, :phone_number, :email, :cpf,
    :check_in_at, :check_out_at, :total_amount, :duration_minutes,
    metadata: {}
  )
end
```

## 2. Erro de Validação: `Validation failed: Conversation must exist`

**Sintoma:**
Erro 422: `Validation failed: Conversation must exist`.

**Causa:**
O modelo `Captain::Reservation` possui uma validação de presença (`belongs_to`) para `conversation`. No entanto, o fluxo inicial criava apenas o Contato, mas não iniciava uma conversa, falhando a validação ao tentar salvar a reserva.

**Solução:**
Adicionada a criação de uma `::Conversation` antes de criar a reserva no controlador:

```ruby
# A. Find or Create Contact
contact = find_or_create_contact(reservation_params)

# A.1 Find or Create Conversation
inbox_id = unit.account.inboxes.first&.id
conversation = ::Conversation.create!(
  account_id: unit.account_id,
  inbox_id: inbox_id,
  contact_id: contact.id,
  contact_inbox_id: ::ContactInbox.find_by(contact_id: contact.id, inbox_id: inbox_id)&.id,
  status: :open
)

# ... ao criar a reserva, passamos conversation.id
```

## 3. Erro na Geração do Pix: `can't convert nil into Float`

**Sintoma:**
Erro interno no `InterService` ao tentar gerar o Pix: `can't convert nil into Float`.

**Causa:**
Discrepância nos parâmetros passados entre o Controlador e o Serviço.

- O Controlador enviava: `{ total_amount: 40.0, contact_name: "Fulano" }`
- O Serviço (`InterService`) esperava: `{ amount: 40.0, name: "Fulano" }`

O serviço tentava acessar `reservation[:amount]`, que retornava `nil`, causando o erro ao formatar para float.

**Solução:**
O `InterService` foi ajustado para usar as chaves enviadas pelo controlador:

```ruby
devedor: {
  nome: reservation[:contact_name] # Antes: reservation[:name]
},
valor: {
  original: format('%.2f', reservation[:total_amount].to_f) # Antes: reservation[:amount]
}
```

## 4. Sanitização de Dados (Frontend)

**Solicitação:**
Enviar CPF e Telefone sem formatação (apenas números).

**Solução:**
No `App.vue`, os dados são limpos antes do envio da requisição:

```javascript
const payload = {
  // ...
  phone_number: formData.telefone.replace(/\D/g, ''), // Remove ( ) -
  cpf: formData.cpf.replace(/\D/g, ''), // Remove . -
  // ...
};
```
