json.payload do
  json.array! @frequent_questions do |fq|
    json.id fq.id
    json.question_text fq.question_text
    json.occurrence_count fq.occurrence_count
    json.cluster_date fq.cluster_date
  end
end
