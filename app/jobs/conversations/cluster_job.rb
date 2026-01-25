class Conversations::ClusterJob < ApplicationJob
  queue_as :low_priority

  def perform(account_id, days_back = 7)
    account = Account.find(account_id)

    # 1. Busca conversas recentes que já foram processadas pela IA
    start_date = days_back.days.ago.beginning_of_day

    # Labels que queremos agrupar (todas da taxonomia)
    Conversations::AutoLabelJob::TAXONOMY.each_key do |label|
      # Busca perguntas dessa categoria
      # Note: estamos queryng o campo JSONB additional_attributes
      account.conversations
             .where('created_at >= ?', start_date)
             .where("additional_attributes ->> 'ai_canonical_question' IS NOT NULL")
             .tagged_with(label)
             .pluckArel::Nodes::InfixOperation.new('->>', Arel::Nodes::SqlLiteral.new('additional_attributes'), Arel::Nodes::SqlLiteral.new("'ai_canonical_question'"))

      # O pluck acima pode ser complexo dependendo do adapter, vamos simplificar:
      questions = account.conversations
                         .where('created_at >= ?', start_date)
                         .where("additional_attributes ->> 'ai_canonical_question' IS NOT NULL")
                         .tagged_with(label)
                         .map { |c| c.additional_attributes['ai_canonical_question'] }

      next if questions.empty?

      # 2. Chama LLM para agrupar
      clusters = cluster_questions_with_llm(label, questions)

      # 3. Salva no banco
      save_clusters(account, label, clusters, start_date.to_date)
    end
  end

  private

  def cluster_questions_with_llm(label, questions_list)
    prompt = <<~PROMPT
      Atue como um analista de dados especialista em atendimento ao cliente.
      Abaixo está uma lista de dúvidas reais de clientes sobre o tópico "#{label}".

      Sua tarefa:
      1. Agrupar dúvidas semânticamente idênticas.
      2. Criar uma "Pergunta Padrão" clara que represente o grupo.
      3. Contar quantas vezes cada dúvida apareceu.

      Lista de Dúvidas:
      #{questions_list.map { |q| "- #{q}" }.join("\n")}

      Retorne APENAS um JSON:
      [
        { "question": "Pergunta Padrão 1", "count": 10 },
        { "question": "Pergunta Padrão 2", "count": 5 }
      ]
    PROMPT

    model = ENV.fetch('JASMINE_LLM_MODEL', 'gpt-4o-mini')
    chat = RubyLLM.chat(model: model).with_temperature(0.0)
    response = chat.ask(prompt)

    clean_response = response.content.gsub('```json', '').gsub('```', '').strip
    JSON.parse(clean_response)
  rescue StandardError => e
    Rails.logger.error "[ClusterJob] Failed to cluster for label #{label}: #{e.message}"
    []
  end

  def save_clusters(account, label, clusters, date)
    # Limpa clusters anteriores dessa data/label para reprocessamento
    FrequentQuestion.where(account: account, label: label, cluster_date: date).destroy_all

    clusters.each do |cluster|
      FrequentQuestion.create!(
        account: account,
        label: label,
        question_text: cluster['question'],
        occurrence_count: cluster['count'],
        cluster_date: date
      )
    end
  end
end
