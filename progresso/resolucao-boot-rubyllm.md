# Resolução: Boot Loop (RubyLLM) e Onboarding Infinito

## Objetivo

Corrigir falha na inicialização do container (CrashLoopBackoff) e redirecionamento incorreto para o fluxo de onboarding após atualização da stack.

## Contexto

1. **Erro de Boot**: O arquivo `config/initializers/ruby_llm.rb` tentava configurar `google_api_key`, propriedade inexistente na versão atual da gem, causando exceção fatal na inicialização do Rails.
2. **Onboarding Infinito**: O arquivo `db/seeds.rb` setava incondicionalmente a chave Redis de onboarding em produção, fazendo com que usuários existentes fossem redirecionados para criar conta (causando erro de chave duplicada).
3. **Falta de Versionamento**: Impossibilidade de verificar qual versão do código estava rodando no container.

## Alterações Realizadas

### 1. Correção `config/initializers/ruby_llm.rb`

- Removida a linha `config.google_api_key = ...`.
- Adicionado bloco `begin/rescue` para capturar erros de configuração do LLM sem derrubar a aplicação.

### 2. Correção `db/seeds.rb`

- Adicionada verificação `if User.count.zero?` antes de ativar o modo onboarding.

### 3. Versionamento `docker/Dockerfile`

- Adicionado suporte a `ARG BUILD_SHA`.
- O hash do commit é persistido em `/app/BUILD_SHA` durante o build.

## Como Validar

1. Acessar console do container.
2. `cat /app/BUILD_SHA` deve mostrar "dev" ou o hash do commit.
3. `bundle exec rails runner "puts 'OK'"` deve rodar sem erros de `undefined method`.
4. Acessar a home não deve redirecionar para `/installation/onboarding`.

## Reversão

Reverter os commits nos arquivos citados.
