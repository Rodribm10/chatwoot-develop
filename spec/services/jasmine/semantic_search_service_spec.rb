require 'rails_helper'

RSpec.describe Jasmine::SemanticSearchService do
  let!(:account) { create(:account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:config) { create(:jasmine_inbox_config, inbox: inbox, account: account, is_enabled: true) }
  
  let!(:collection_private) { create(:jasmine_collection, name: "Private", visibility: :private, owner_inbox: inbox, account: account) }
  let!(:collection_shared) { create(:jasmine_collection, name: "Shared", visibility: :shared, account: account) }
  
  # Link collections: Private (High Priority), Shared (Low Priority)
  let!(:link_private) { create(:jasmine_inbox_collection, inbox: inbox, collection: collection_private, priority: 10, account: account) }
  let!(:link_shared) { create(:jasmine_inbox_collection, inbox: inbox, collection: collection_shared, priority: 0, account: account) }

  let!(:doc_private) { create(:jasmine_document, collection: collection_private, content: "Private Secret", account: account) }
  let!(:doc_shared) { create(:jasmine_document, collection: collection_shared, content: "Shared Knowledge", account: account) }

  # Mock Embedding Service behavior by creating chunks directly with known vectors
  # Query Vector: [1.0, 0.0, ...]
  # Private Match: [0.9, 0.0, ...] -> Distance ~0.1
  # Shared Match: [0.8, 0.0, ...] -> Distance ~0.2 (Worse match but still good)
  # Irrelevant: [0.0, 1.0, ...] -> Distance ~1.0
  
  before do
    # Create chunks manually to bypass job/api dependency
    create_chunk(doc_private, [0.9] + [0.0]*1535)
    create_chunk(doc_shared, [0.8] + [0.0]*1535)
  end

  def create_chunk(doc, vec)
    Jasmine::DocumentChunk.create!(
      document: doc,
      collection: doc.collection,
      account: doc.account,
      content: doc.content,
      embedding: vec
    )
  end

  subject { described_class.new(inbox) }

  describe '#search' do
    it 'returns results from enabled collections' do
      # Mock the embedding generation for the query
      allow(RubyLLM).to receive(:embed).and_return(OpenStruct.new(vectors: [[1.0] + [0.0]*1535]))

      results = subject.search("Query")
      expect(results.size).to be >= 2
      expect(results.first.content).to eq("Private Secret")
    end

    it 'respects priority (waterfall)' do
      allow(RubyLLM).to receive(:embed).and_return(OpenStruct.new(vectors: [[1.0] + [0.0]*1535]))
      
      # Even if shared has a PERFECT match, if Private has a "Good Enough" match (below threshold),
      # does the waterfall prioritize Private?
      # The algorithm gathers candidates from Groups (Priority 10 first).
      # Then it filters/reranks.
      # If Priority 10 fills the FINAL_LIMIT, Priority 0 is skipped.
      
      # Let's limit the service to 1 result to test waterfall
      # stub_const("Jasmine::SemanticSearchService::FINAL_LIMIT", 1) # Removed as service uses arg
      
      results = subject.search("Query", limit: 1)
      expect(results.size).to eq(1)
      expect(results.first.content).to eq("Private Secret") # Should be from High Priority collection
    end

    it 'filters out results above threshold' do
      # Create a bad chunk
      bad_doc = create(:jasmine_document, collection: collection_private, account: account)
      create_chunk(bad_doc, [0.0] + [1.0]*1535) # Orthogonal/Opposite
      
      allow(RubyLLM).to receive(:embed).and_return(OpenStruct.new(vectors: [[1.0] + [0.0]*1535]))
      
      results = subject.search("Query")
      expect(results.map(&:content)).not_to include(bad_doc.content)
    end
  end
end
