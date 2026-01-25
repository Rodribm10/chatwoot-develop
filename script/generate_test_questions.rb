# script/generate_test_questions.rb

account = Account.first
unless account
  puts 'Nenhuma conta encontrada.'
  exit
end
dates = [Time.zone.today, Date.yesterday, 1.week.ago.to_date]

questions_data = [
  { text: 'Aceita pagamento via PIX?', count: 45, label: 'duvida_valores' },
  { text: 'Qual o valor da diária para casal?', count: 32, label: 'duvida_valores' },
  { text: 'Tem desconto para pagamento à vista?', count: 12, label: 'duvida_valores' },
  { text: 'Qual o horário do café da manhã?', count: 50, label: 'duvida_horario' },
  { text: 'Posso fazer check-in antecipado?', count: 28, label: 'duvida_horario' },
  { text: 'Aceita cachorro de pequeno porte?', count: 15, label: 'duvida_pet' },
  { text: 'Tem taxa extra para levar gato?', count: 8, label: 'duvida_pet' }
]

puts 'Limpando dados antigos...'
FrequentQuestion.where(account: account).destroy_all

puts 'Gerando novos dados de teste...'
questions_data.each do |data|
  FrequentQuestion.create!(
    account: account,
    label: data[:label],
    question_text: data[:text],
    occurrence_count: data[:count],
    cluster_date: dates.sample
  )
end

puts "Sucesso! #{FrequentQuestion.count} registros criados."
