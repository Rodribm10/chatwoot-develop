# Nota de Resolução: Configuração de Ambiente Ruby 3.4.4 e Correção de Serialização

## Objetivo

Configurar o ambiente de desenvolvimento do Chatwoot para a versão de Ruby exigida e resolver impedimentos de inicialização do banco de dados e servidor.

## Contexto

O projeto Chatwoot exige Ruby 3.4.4 e Rails 7.1. Versões anteriores do Ruby ou ferramentas ausentes (Overmind) impossibilitavam a execução de lints e do servidor. Além disso, uma incompatibilidade no modelo `InstallationConfig` causava erros de tipo durante o parse de YAML no Ruby 3.4.

## Passos Realizados

1.  **Instalação de Ferramentas**:
    - `brew install ruby-install chruby overmind`
    - `ruby-install ruby 3.4.4`
2.  **Configuração de Shell**:
    - Adicionado `source /opt/homebrew/opt/chruby/share/chruby/chruby.sh` e `source /opt/homebrew/opt/chruby/share/chruby/auto.sh` ao `~/.zshrc` e `~/.bash_profile`.
3.  **Dependências**:
    - `gem install bundler:2.5.11`
    - `bundle install`
4.  **Correção de Código**:
    - Alterado [InstallationConfig.rb](file:///Users/user/Dev/Produtos/Chatwoot/chatwoot-develop/app/models/installation_config.rb) para lidar com a coluna `serialized_value` (JSONB) de forma resiliente, permitindo parse de YAML legado caso necessário, mas evitando falhas de tipo no Rails 7.1.

## Principais Arquivos Alterados

- [InstallationConfig.rb](file:///Users/user/Dev/Produtos/Chatwoot/chatwoot-develop/app/models/installation_config.rb): Ajuste nos métodos `value` e remoção da macro `serialize` redundante.
- `~/.zshrc` / `~/.bash_profile`: Atualização de paths e scripts de ambiente.

## Como Validar

1.  Execute `source ~/.zshrc`.
2.  Rode `bundle exec rails db:chatwoot_prepare`.
3.  Inicie o stack com `make run`.

## Como Reverter

1.  Remover os `source` do `~/.zshrc`.
2.  Restaurar o modelo `InstallationConfig.rb` para o estado original (utilizando `serialize ... coder: YAML`).
