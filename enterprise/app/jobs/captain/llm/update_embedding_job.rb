class Captain::Llm::UpdateEmbeddingJob < ApplicationJob
  queue_as :low

  def perform(record, content)
    account_id = record.account_id
    Rails.logger.info(
      "[CAPTAIN][embedding] Generating embedding for record_id=#{record.id} account_id=#{account_id} type=#{record.class.name}"
    )
    embedding = Captain::Llm::EmbeddingService.new(account_id: account_id).get_embedding(content)
    record.update!(embedding: embedding)
    Rails.logger.info(
      "[CAPTAIN][embedding] Stored embedding for record_id=#{record.id} vector_size=#{embedding&.length}"
    )
  end
end
