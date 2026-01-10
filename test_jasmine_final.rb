# test_jasmine_final.rb
assistant = Captain::Assistant.find_by(name: 'Jasmine (Hotel Prime)')

def test_msg(assistant, msg)
  puts "\n> Cliente: #{msg}"
  # Usando o serviço de chat direto para validar o prompt
  service = Captain::Llm::AssistantChatService.new(assistant: assistant)
  res = service.generate_response(additional_message: msg)
  puts "< Jasmine: #{res['response']}"
  puts "  (Sentimento: #{res['sentiment']})"
  puts "  (Raciocínio: #{res['reasoning']})"
end

test_msg(assistant, "Oi, qual o valor da pernoite na Alexa?")
test_msg(assistant, "Quero reservar para amanhã 22h")
test_msg(assistant, "ESTOU COM MUITA RAIVA!")

