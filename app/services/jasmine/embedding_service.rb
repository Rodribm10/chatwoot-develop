module Jasmine
  class EmbeddingService
    CHUNK_SIZE = 1000
    CHUNK_OVERLAP = 200
    EMBEDDING_DIMENSIONS = 1536 # OpenAI text-embedding-3-small dimensions

    def initialize(document)
      @document = document
    end

    def process
      @document.with_lock do
        return if @document.indexed?

        @document.update!(status: :processing)
        @document.chunks.delete_all

        chunks = chunk_content(@document.content)
        create_chunks(chunks)

        @document.update!(status: :indexed)
      end
    rescue StandardError => e
      @document.update!(status: :failed, error_message: e.message)
      Rails.logger.error "Embedding failed for Doc ID #{@document.id}: #{e.message}"
    end

    private

    def chunk_content(content)
      chunks = []
      return chunks if content.blank?

      start_index = 0
      chunk_index = 0
      
      while start_index < content.length
        end_index = [start_index + CHUNK_SIZE, content.length].min
        
        if end_index < content.length
          last_space = content[start_index...end_index].rindex(' ')
          end_index = start_index + last_space if last_space
        end

        chunk_text = content[start_index...end_index].strip
        
        if chunk_text.present?
          chunks << {
            content: chunk_text,
            index: chunk_index,
            char_start: start_index,
            char_end: end_index
          }
          chunk_index += 1
        end

        break if end_index >= content.length
        
        start_index = end_index - CHUNK_OVERLAP
        start_index = [start_index, end_index].max if start_index <= (end_index - CHUNK_SIZE) 
      end

      chunks
    end

    def create_chunks(chunks)
      return if chunks.empty?

      chunks.each do |chunk_data|
        embedding = generate_embedding(chunk_data[:content])
        
        Jasmine::DocumentChunk.create!(
          account: @document.account,
          collection: @document.collection,
          document: @document,
          content: chunk_data[:content],
          metadata: {
            chunk_index: chunk_data[:index],
            char_start: chunk_data[:char_start],
            char_end: chunk_data[:char_end],
            model: embedding_model
          },
          embedding: embedding
        )
      end
    end

    def generate_embedding(text)
      if openai_configured?
        generate_openai_embedding(text)
      else
        # Fallback: Generate deterministic hash-based embedding for testing
        # This won't provide semantic search but allows the system to function
        Rails.logger.warn "OpenAI not configured, using fallback embedding for Jasmine"
        generate_fallback_embedding(text)
      end
    end

    def openai_configured?
      ENV['OPENAI_API_KEY'].present?
    end

    def generate_openai_embedding(text)
      response = RubyLLM.embed(text, model: embedding_model)
      response.vectors.first
    end

    def generate_fallback_embedding(text)
      # Generate a deterministic pseudo-random vector based on text content
      # Uses SHA256 hash to seed random number generator for reproducibility
      require 'digest'
      
      seed = Digest::SHA256.hexdigest(text.downcase.gsub(/\s+/, ' ').strip).to_i(16) % (2**32)
      rng = Random.new(seed)
      
      # Generate normalized vector with EMBEDDING_DIMENSIONS dimensions
      vector = Array.new(EMBEDDING_DIMENSIONS) { rng.rand(-1.0..1.0) }
      
      # Normalize to unit length
      magnitude = Math.sqrt(vector.sum { |v| v**2 })
      vector.map { |v| v / magnitude }
    end

    def embedding_model
      ENV.fetch('JASMINE_EMBEDDING_MODEL', 'text-embedding-3-small')
    end
  end
end

