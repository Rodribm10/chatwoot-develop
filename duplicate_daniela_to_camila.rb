# duplicate_daniela_to_camila.rb
daniela = Captain::Scenario.find_by(title: 'Daniela Reservas')

if daniela
  camila = daniela.dup
  camila.title = 'Camila Reservas'
  camila.instruction = daniela.instruction # Ensure instructions are copied
  camila.tools = daniela.tools # Ensure tools are copied

  if camila.save
    puts "SUCCESS: Camila Reservas created with ID: #{camila.id}"
  else
    puts "ERROR: Failed to create Camila. Errors: #{camila.errors.full_messages}"
  end
else
  puts 'ERROR: Daniela Reservas not found.'
end
