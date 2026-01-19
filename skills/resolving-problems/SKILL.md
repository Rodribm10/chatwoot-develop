---
name: resolving-problems
description: A universal framework for diagnosing and resolving technical problems (bugs, errors, failures) in any application. Use when the user presents a generic error or bug.
---

# Objetivo

Fornecer um roteiro estruturado para investigar, diagnosticar e corrigir problemas de forma eficiente, evitando "tentativa e erro" aleatória. Esta skill deve ser usada sempre que o usuário apresentar um erro genérico, um bug, ou uma falha inesperada.

# 1. Definição e Entendimento

Antes de qualquer alteração de código, é crucial entender o cenário.

**Perguntas Chave:**

1. **O que está acontecendo?** (Descreva o sintoma exato, mensagem de erro).
2. **O que deveria acontecer?** (Comportamento esperado).
3. **Qual o impacto?** (Crítico, bloqueante, visual, cosmético).
4. **Onde ocorre?** (Ambiente local, produção, URL específica, componente específico).

# 2. Reprodução

Se você não consegue reproduzir, você não consegue consertar (ou verificar a correção).

**Ações:**

- **Identifique os passos:** Crie um roteiro passo-a-passo (A -> B -> C) que causa o erro consistentemente.
- **Logs em Tempo Real:** Abra os logs (`tail -f log/development.log`, logs do container, console do navegador) _enquanto_ executa a reprodução.
- **Isolamento de Variáveis:** O erro persiste se trocar o navegador? Se trocar o usuário?

# 3. Diagnóstico e Isolamento

Reduza o escopo para encontrar a raiz do problema.

**Estratégia de Divisão (Divide and Conquer):**

- **Frontend vs Backend:**

  - Verifique a aba **Network** do navegador.
  - Se a requisição falha (500, 404), o problema provável é no **Backend**.
  - Se a requisição retorna sucesso (200) mas a tela quebra ou mostra dados errados, o problema provável é no **Frontend**.
  - Se nem há requisição, o erro é no JS do **Frontend** antes do envio.

- **Stack Trace Analysis:**
  - **NUNCA ignore o Stack Trace.** Leia a primeira linha que aponta para _o código da aplicação_ (ignore linhas de bibliotecas/gems inicialmente).
  - Identifique a Exception exata e a linha do arquivo.

# 4. Ferramentas de Investigação

Use as ferramentas disponíveis no ambiente.

- **Pesquisa no Código (Grep/Search):** Procure pela mensagem de erro ou pelo código do erro para achar onde ele é disparado.
- **Debugger:**
  - **Ruby:** Adicione `binding.pry` antes da linha suspeita.
  - **JS:** Adicione `debugger;` ou `console.log` antes da linha suspeita.
- **Database:** Verifique se os dados no banco correspondem ao esperado (`Rails Console`, `psql`).

# 5. Aplicação da Solução

Ao identificar a causa raiz, planeje a correção.

**Princípios:**

- **Corrija a Causa, não o Sintoma:** Se uma variável é nula, entenda _por que_ ela é nula, não apenas coloque um `if variable`.
- **Mudança Mínima:** Evite refatorar código não relacionado ao bug enquanto corrige o bug.
- **Defensividade:** Adicione tratamentos de erro adequados se o erro for causado por inputs externos imprevisíveis.

# 6. Verificação e Documentação

Garanta que o problema sumiu e não voltará.

**Passos:**

1. **Teste a Reprodução:** Execute os passos da etapa 2 novamente. O erro deve ter desaparecido.
2. **Teste Casos de Borda:** Teste variações (input vazio, input inválido).
3. **Documentação:** Se o problema foi complexo, crie uma nota em `/progresso` explicando o problema e a solução para referência futura.

# Dicas Específicas por Tecnologia

## Ruby on Rails

- **Erro de Rota?** Rode `rails routes | grep termo`.
- **Erro de DB?** Verifique `schema.rb` e migrations.
- **Console:** Use `rails c` para instanciar modelos e chamar métodos diretamente, isolando a camada HTTP.

## Vue.js / Frontend

- **Vue DevTools:** Inspecione a hierarquia de componentes. O componente recebeu as `props` certas? O `data` está correto?
- **Console:** Se o erro é "undefined is not a function", verifique imports e tipos.

## Infraestrutura

- **Serviços Rodando?** Verifique se Redis, Postgres, Sidekiq estão rodando (`docker ps`, `ps aux`).
- **Variáveis de Ambiente:** Verifique `.env`.
