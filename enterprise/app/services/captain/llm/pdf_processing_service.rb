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
    ensure_pdf_reader!
    content = ''
    document.pdf_file.open do |file|
      reader = PDF::Reader.new(file)
      content = reader.pages.map(&:text).join("\n")
    end

    if content.present?
      Rails.logger.info "PDF extracted content for document #{document.id} (chars=#{content.length})"
      # Update content and clear openai_file_id in metadata to force standard FAQ generation.
      metadata = (document.metadata || {}).merge('openai_file_id' => nil)
      document.update!(content: content, metadata: metadata)
    else
      Rails.logger.warn "PDF extracted content is empty for document #{document.id}"
    end
  end

  def ensure_pdf_reader!
    return if defined?(PDF::Reader)

    require 'pdf/reader'
  rescue LoadError => e
    Rails.logger.error "PDF Processing Error: missing pdf-reader gem (#{e.message})"
    raise e
  end
end
