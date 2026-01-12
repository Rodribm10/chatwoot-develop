# Fix: Erro 401 em Custom Tools (Headers Customizados)

**Data:** 11/01/2026
**Autor:** Antigravity
**Contexto:**
A ferramenta `custom_status_suites` (usada pelo sub-agente `jamile_disponibilidade_imediata`) estava retornando erro **401 Unauthorized**.
Motivo: A API externa exigia headers específicos (`PLUG-PLAY-ID`, `PLUG-PLAY-TOKEN`), mas a interface do Chatwoot só permitia configurar autenticação do tipo Bearer, Basic ou uma única API Key. Não havia suporte para múltiplos headers arbitrários.

---

## 🚀 Solução

Implementamos uma nova seção no formulário de Custom Tools para permitir a adição de **Headers Personalizados** (Key-Value) ilimitados. Esses headers são anexados a todas as requisições da ferramenta.

### 1. Alterações no Frontend (Vue.js)

- **Novo Componente:** `app/javascript/dashboard/components-next/captain/pageComponents/customTool/HeaderRow.vue`
  - Gerencia uma linha de input (Chave e Valor) com validação.
- **Update no Formulário:** `app/javascript/dashboard/components-next/captain/pageComponents/customTool/CustomToolForm.vue`
  - Adicionada lista de `customHeaders`.
  - Lógica para converter o array visual em Hash `auth_config['headers']` no submit.
  - Lógica para popular o formulário ao editar uma tool existente.
- **Traduções:** Adicionadas chaves `HEADERS`, `ADD_HEADER`, etc., em `en/integrations.json` e `pt_BR/integrations.json`.

### 2. Backend (Ruby on Rails)

- O backend (`Enterprise::Concerns::Toolable#build_auth_headers`) já estava preparado para ler `auth_config['headers']`. Nenhuma alteração lógica foi necessária, apenas habilitar a entrada de dados via UI.

### 3. Script de Correção (Produção)

Para corrigir ferramentas em produção sem precisar redeployar o frontend imediatamente, ou para ajustes em massa:

**Script:** `scripts/debug_status_suites.rb`

```bash
# Como rodar no terminal do servidor/container
bundle exec rails runner scripts/debug_status_suites.rb
```

O script:

1.  Busca a ferramenta por nome/url ("Status Suites").
2.  Verifica se `PLUG-PLAY-ID` e `PLUG-PLAY-TOKEN` estão faltando.
3.  Solicita os valores interativamente.
4.  Salva e executa um teste de conexão.

---

## ✅ Como Validar

1.  Acessar **Captain > Ferramentas**.
2.  Editar a ferramenta desejada.
3.  Na seção **Headers Personalizados**, adicionar as chaves necessárias.
4.  Salvar.
5.  Clicar no botão **Testar** (ícone de play).
6.  O resultado deve ser **200 OK** com o JSON de resposta esperado.
