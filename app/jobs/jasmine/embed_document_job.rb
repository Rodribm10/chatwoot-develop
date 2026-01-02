class Jasmine::EmbedDocumentJob < ApplicationJob
  queue_as :default

  def perform(document_id)
    document = Jasmine::Document.find_by(id: document_id)
    return unless document

    Jasmine::EmbeddingService.new(document).process
  end
end
