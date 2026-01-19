# Cleanup Maria Fotos duplicates
correct_maria = Captain::Scenario.where(title: 'Maria Fotos').where.not(trigger_keywords: nil).last
if correct_maria
  duplicates = Captain::Scenario.where(title: 'Maria Fotos').where.not(id: correct_maria.id)
  duplicates_count = duplicates.count
  duplicates.destroy_all
  puts "Deleted #{duplicates_count} duplicate Maria Fotos agents."
else
  puts 'Correct Maria Fotos not found!'
end

# Enable Jorge
jorge = Captain::Scenario.find_by(title: 'Jorge Financeiro')
if jorge
  jorge.update!(enabled: true)
  puts 'Jorge Financeiro enabled.'
else
  puts 'Jorge Financeiro not found.'
end
