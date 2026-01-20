# == Schema Information
#
# Table name: jasmine_tool_configs
#
#  id                    :bigint           not null, primary key
#  is_enabled            :boolean          default(FALSE), not null
#  last_test_duration_ms :integer
#  last_test_error       :text
#  last_test_status      :integer
#  last_tested_at        :datetime
#  plug_play_token       :text
#  tool_key              :string           not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  account_id            :bigint           not null
#  inbox_id              :bigint           not null
#  plug_play_id          :string
#
# Indexes
#
#  index_jasmine_tool_configs_on_account_id  (account_id)
#  index_jasmine_tool_configs_on_inbox_id    (inbox_id)
#  index_jasmine_tool_configs_on_tool_key    (tool_key)
#  index_jasmine_tools_on_account_inbox_key  (account_id,inbox_id,tool_key) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (inbox_id => inboxes.id)
#
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
