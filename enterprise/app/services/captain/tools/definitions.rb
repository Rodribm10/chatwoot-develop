module Captain
  module Tools
    class Definitions
      ALL = {
        'status_suites' => {
          type: :http,
          method: :get,
          url: 'https://oxpi.com.br/api/PlugPlay/api/SuitesStatus',
          description: 'Check suite availability'
        },
        'maria_fotos' => {
          type: :webhook,
          description: 'Send photos via webhook'
        },
        'escalar_humano' => {
          type: :webhook,
          description: 'Escalate to human agent'
        },
        'react_to_message' => {
          type: :internal,
          name: 'Reagir a Mensagens',
          description: 'React to customer messages with emoji (👍, ❤️, 😊)'
        }
      }.freeze
    end
  end
end
