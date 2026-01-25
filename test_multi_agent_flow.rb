# test_multi_agent_flow.rb
assistant = Captain::Assistant.find_by(name: 'Jasmine (Hotel Prime)')

def simulate_handoff(assistant, user_msg)
  puts "\n=========================================================="
  puts "USUÁRIO: #{user_msg}"

  # Usando o motor Multi-Agente (V2) sem conversation real para o Playground
  runner = Captain::Assistant::AgentRunnerService.new(assistant: assistant)

  # Capturando o resultado do motor
  result = runner.generate_response(message_history: [{ role: 'user', content: user_msg }])

  puts "AGENTE QUE RESPONDEU: #{result['agent_name']}"
  puts "RESPOSTA FINAL: #{result['response']}"
  puts "RACIOCÍNIO: #{result['reasoning']}"
  puts "SENTIMENTO: #{result['sentiment']}"
  puts '=========================================================='
end

simulate_handoff(assistant, 'Gostaria de agendar um quarto para amanhã às 22h')
