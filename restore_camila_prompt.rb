danielas = Captain::Scenario.where(title: 'Daniela Reservas')
camila = Captain::Scenario.find_by(title: 'Camila Reservas')

if danielas.empty?
  puts 'ERROR: Daniela Reservas not found!'
  exit
end

# Pick the one with content if multiple, or just the first
daniela = danielas.find { |d| d.instruction.present? } || danielas.first

if camila
  puts 'Found Camila. Checking instructions...'
  if camila.instruction.blank? || camila.instruction != daniela.instruction
    puts "Updating Camila's instruction from Daniela..."
    camila.instruction = daniela.instruction
    camila.tools = daniela.tools
    if camila.save
      puts 'SUCCESS: Camila Reservas instruction restored.'
    else
      puts "ERROR: Failed to update Camila: #{camila.errors.full_messages}"
    end
  else
    puts 'Camila already has the correct instruction.'
  end
else
  puts 'Camila record not found. Creating new clone...'
  camila = daniela.dup
  camila.title = 'Camila Reservas'
  if camila.save
    puts 'SUCCESS: Camila Reservas created.'
  else
    puts "ERROR: Failed to create Camila: #{camila.errors.full_messages}"
  end
end
