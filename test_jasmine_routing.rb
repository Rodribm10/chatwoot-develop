# test_jasmine_routing.rb
# Objetivo: Testar se a Orquestradora Jasmine roteia corretamente as intenções.

assistant = Captain::Assistant.find_by(name: 'Jasmine (Hotel Prime)')
unless assistant
  puts "Assistente Jasmine não encontrada. Execute o seed primeiro."
  exit
end

def simulate_chat(assistant, message)
  puts "\n--- CLIENTE: #{message}"
  
  # Usamos o AgentRunnerService (V2) que é o que suporta handoffs/sub-agentes
  runner = Captain::Assistant::AgentRunnerService.new(assistant: assistant)
  
  # Simulamos o histórico com apenas a última mensagem do usuário
  history = [{ role: 'user', content: message }]
  
  response = runner.generate_response(message_history: history)
  
  puts "--- JASMINE RESPONDE:"
  puts "DEBUG: #{response.inspect}"
  puts "Pensamento: #{response['reasoning']}"
  puts "Agente Atual: #{response['agent_name'] || 'Orquestrador'}"
  puts "Resposta: #{response['response']}"
  puts "Sentimento Detectado: #{response['sentiment']}"
end

# Casos de Teste
simulate_chat(assistant, "Oi, quanto custa a pernoite na suite Alexa?")
simulate_chat(assistant, "Quero reservar para sabado que vem às 20h.")
simulate_chat(assistant, "Tem suite livre agora? To chegando em 10 minutos.")
simulate_chat(assistant, "Pode me mandar fotos da suite com hidro?")
simulate_chat(assistant, "ESTOU MUITO IRRITADO COM A DEMORA!") # Teste de sentimento
