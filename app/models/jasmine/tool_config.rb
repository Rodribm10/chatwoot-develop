module Jasmine
  class ToolConfig < ApplicationRecord
    self.table_name = 'jasmine_tool_configs'

    belongs_to :account
    belongs_to :inbox

    # Token encryption using Rails 7 native encryption
    encrypts :plug_play_token if Chatwoot.encryption_configured?

    validates :tool_key, presence: true
    validates :plug_play_id, presence: true, if: :is_enabled?
    validates :plug_play_token, presence: true, if: :is_enabled?

    # Fixed Tool Definitions
    DEFINITIONS = {
      'status_suites' => {
        name: 'Status das Suítes',
        method: :get,
        url: 'https://oxpi.com.br/api/PlugPlay/api/SuitesStatus',
        description: 'Verifica o status atual das suítes.'
      },
      'listar_reservas' => {
        name: 'Listar Reservas',
        method: :get,
        url: 'https://oxpi.com.br/api/PlugPlay/api/Reserva?exibicao=0&pagina=1',
        description: 'Lista as reservas ativas.'
      },
      'categoria_disponibilidade' => {
        name: 'Disponibilidade por Categoria',
        method: :get,
        url: 'https://oxpi.com.br/api/PlugPlay/api/CategoriaDisponibilidade',
        description: 'Verifica disponibilidade de categorias.'
      }
    }.freeze

    def self.definitions
      DEFINITIONS
    end
  end
end
