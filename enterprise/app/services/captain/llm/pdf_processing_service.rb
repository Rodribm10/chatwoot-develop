class Captain::Llm::PdfProcessingService < Llm::LegacyBaseOpenAiService
  include Integrations::LlmInstrumentation

  def initialize(document)
    super()
    @document = document
  end

  def process
    return if document.content.present?

    extract_text_from_pdf
  rescue StandardError => e
    Rails.logger.error "PDF Processing Error: #{e.message}"
    raise e
  end

  private

  attr_reader :document

  def extract_text_from_pdf
    content = ''
    document.pdf_file.open do |file|
      reader = PDF::Reader.new(file)
      content = reader.pages.map(&:text).join("\n")
    end

    if content.present?
      # Update content and ensure openai_file_id is nil to force standard FAQ generation
      document.update!(content: content, openai_file_id: nil)
    else
      Rails.logger.warn "PDF extracted content is empty for document #{document.id}"
    end
  end
end
