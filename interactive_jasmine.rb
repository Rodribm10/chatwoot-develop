# interactive_jasmine.rb
assistant = Captain::Assistant.find_by(name: 'Jasmine (Hotel Prime)')

unless assistant
  puts "Erro: Jasmine não encontrada. Execute o seed primeiro."
  exit
end

puts "=========================================================="
puts " JASMINE INTERATIVA - HOTEL 1001 NOITES PRIME "
puts "=========================================================="
puts "Digite sua mensagem (ou 'sair' para encerrar):"

loop do
  print "\nVocê: "
  input = gets.chomp
  break if input.downcase == 'sair'

  puts "..."
  puts "(Jasmine está processando e digitando...)"
  
  # Usando o job oficial para testar a latência e o status de digitação que implementamos
  service = Captain::Llm::AssistantChatService.new(assistant: assistant)
  start_time = Time.zone.now
  
  res = service.generate_response(additional_message: input)
  
  # Simulação da lógica de latência que está no Job
  response_text = res['response']
  typing_speed = 50
  target_delay = (response_text.length * typing_speed) / 1000.0
  target_delay = [target_delay, 7.0].min
  elapsed = Time.zone.now - start_time
  remaining = target_delay - elapsed
  
  sleep(remaining) if remaining > 0

  puts "\nJasmine: #{response_text}"
  puts "\n[DEBUG]"
  puts "Sentimento: #{res['sentiment']}"
  puts "Raciocínio: #{res['reasoning']}"
  puts "Tempo de 'digitação': #{(elapsed + [remaining, 0].max).round(2)}s"
  puts "----------------------------------------------------------"
end
