# Implementação do Pix Seguro "Stateful" (Baseado em Estado)

**Data:** 14/01/2026
**Autor:** Antigravity (Agent)

## 1. O Problema (Abordagem Anterior)

Anteriormente, a ferramenta `GeneratePixTool` era "Stateless" (sem memória). O Agente precisava passar todos os parâmetros de uma vez:
`generate_pix(nome: "João", cpf: "123", valor: 150, suite: "Stilo")`

**Riscos:**

- A IA podia "esquecer" um parâmetro (ex: CPF) e a ferramenta falhava.
- A IA podia "alucinar" um preço (ex: inventar R$ 100 em vez de R$ 150).
- Dificuldade em lidar com tabelas de preços complexas (fins de semana, feriados).

## 2. A Solução (Abordagem "Stateful")

Transformamos o processo em um fluxo de **4 Etapas Seguras**. O "cérebro" do preço e dos dados agora fica no Banco de Dados (`Captain::Pricing` e `Captain::Reservation`), não na memória volátil da IA.

### O Novo Fluxo

#### Passo 1: Atualização de Dados (Cadastro)

- **Ferramenta:** `update_contact_info`
- **Uso:** Quando o cliente informa Nome e CPF.
- **Ação:** Salva os dados na tabela de contatos do Chatwoot.
- **Segurança:** Garante que o CPF está salvo antes de qualquer transação financeira.

#### Passo 2: Consulta de Valor (O "Cardápio")

- **Ferramenta:** `check_availability(suite: 'Categoria')`
- **Uso:** Quando o cliente pergunta "Quanto tá?".
- **Ação:** Consulta a tabela `Captain::Pricing` (NOVA).
- **Retorno:** "A Suíte Stilo custa R$ 150,00". O preço vem do banco, impossível de ser inventado.

#### Passo 3: Intenção de Reserva (O "Rascunho")

- **Ferramenta:** `create_reservation_intent(suite: 'Categoria', price: 150)`
- **Uso:** Quando o cliente diz "Eu quero reservar".
- **Ação:** Cria um registro na tabela `Captain::Reservation` com status `draft` (rascunho).
- **Segurança:** "Trava" o preço e a suíte escolhida no banco de dados.

#### Passo 4: Pagamento (O "Caixa")

- **Ferramenta:** `generate_pix` (Sem parâmetros!)
- **Uso:** Quando o cliente pede "Manda o Pix".
- **Ação:**
  1. Busca a última reserva em `draft` vinculada à conversa.
  2. Lê o valor travado (R$ 150) do banco.
  3. Lê o CPF do contato do banco.
  4. Gera o Pix Copia e Cola via Banco Inter.
- **Segurança:** A IA não tem permissão para alterar valores nesta etapa. Se não houver rascunho com o preço correto, a ferramenta nem executa.

## 3. Mudanças Técnicas Realizadas

- **Banco de Dados:**
  - Criação da tabela `captain_pricings`.
  - Adição do status `draft` em `captain_reservations`.
- **Ferramentas Criadas:**
  - `UpdateContactTool`
  - `CheckAvailabilityTool`
  - `CreateReservationIntentTool`
- **Ferramentas Alteradas:**
  - `GeneratePixTool` (Removidos todos os parâmetros de entrada).

## 4. Como Testar

No WhatsApp automatizado:

1. "Qual o valor da suíte X?" (Testa consulta)
2. "Quero reservar." (Testa rascunho)
3. "Me chamo [Nome], CPF [123...]" (Testa cadastro)
4. "Gera o Pix" (Testa execução blindada)
