module Jasmine
  class SemanticSearchService
    CANDIDATES_PER_PRIORITY = 50
    TOP_K_PER_PRIORITY = 10
    MAX_CHUNKS_PER_DOC = 2
    
    def initialize(inbox)
      @inbox = inbox
      @account_id = inbox.account_id
      @threshold = ENV.fetch('JASMINE_DISTANCE_THRESHOLD', '0.35').to_f
    end

    def search(query, limit: 10)
      # 1. Get enabled collections sorted by priority DESC
      enabled_links = @inbox.inbox_collections
                            .where(is_enabled: true)
                            .order(priority: :desc)
                            .includes(:collection)
      
      return [] if enabled_links.empty?

      # Group by exact priority
      priority_groups = enabled_links.group_by(&:priority)
      
      # Prepare query embedding
      query_embedding = generate_embedding(query)
      
      final_results = []
      processed_chunk_ids = Set.new
      
      # 2. Iterate Priority Groups (Waterfall)
      priority_groups.keys.sort.reverse.each do |priority|
        collection_ids = priority_groups[priority].map(&:collection_id)
        
        # Step 1: ANN/HNSW Candidate Retrieval
        # Find candidates across all collections in this priority group
        # Using raw SQL for precise control over pgvector operator
        candidates = retrieve_candidates(query_embedding, collection_ids)
        
        # Step 2: Rerank, Filter (Threshold), and Dedupe
        group_results = process_candidates(candidates)
        
        # Waterfall Logic
        group_results.each do |result|
          next if processed_chunk_ids.include?(result.id)
          
          final_results << result
          processed_chunk_ids.add(result.id)
          
          break if final_results.size >= limit
        end
        
        break if final_results.size >= limit
      end

      final_results
    end

    private

    def retrieve_candidates(query_embedding, collection_ids)
      # Step 1: Broad search for candidates using HNSW index
      # We order by cosine distance (<=>)
      Jasmine::DocumentChunk
        .where(collection_id: collection_ids)
        .order(Arel.sql("embedding <=> '#{query_embedding}'"))
        .limit(CANDIDATES_PER_PRIORITY)
    end

    def process_candidates(candidates)
      # Step 2: Deterministic Reranking and Filtering
      # Note: 'nearest_neighbors' from neighbor gem already does distance calc, 
      # but we did it manually in retrieve_candidates to ensure we control the operator.
      # We need to manually calculate distance for thresholding if the db didn't return it explicit as a column,
      # or trust the order.
      # Better approach: Select distance in the query.
      
      # Enhanced query with distance
      candidates_with_dist = candidates.select(
        "jasmine_document_chunks.*, (embedding <=> '#{to_pg_vector(candidates.first&.embedding || [])}') as distance"
      )
      
      # Filter by Threshold
      # We need to re-query or calculate.
      # Let's refine retrieve_candidates to include distance.
      
      # Since we are iterating logic here, let's assume retrieve_candidates returns ActiveRecord::Relation.
      # We'll map them to objects and filters.
      
      results = []
      doc_counts = Hash.new(0)
      
      # Calculate distances locally or re-fetch. 
      # Since we ordered by distance in DB, we rely on that order.
      # But we need the value for threshold.
      
      # Let's fix retrieve_candidates to return distance
      # Re-doing retrieval with select
      
      # Correct approach:
      # Iterate, check threshold, check Max Chunks per Doc
      
      candidates.each do |chunk|
        dist = chunk.neighbor_distance(:embedding, @embedding_vector) rescue nil 
        # Note: neighbor gem might not expose distance easily without using its scopes.
        # Fallback: Rely on DB order, but checking absolute threshold might be tricky without the value.
        # Let's trust Neighbor gem's `nearest_neighbors` if possible, but we used raw SQL order.
        
        # To strictly follow plan: "Re-rank exact cosine distance".
        # We can implement a simple ruby cosine distance if vector is loaded, 
        # or use the SQL value.
        
        # Optimization: Let's assume the SQL order is correct (it is).
        # We just need to stop if distance > threshold.
        # Since we can't easily get the distance value without select, let's use neighbor gem scope correctly.
      end
      
      # Better Implementation using Neighbor Gem capabilities which handles this
      # But filtering by priority group AND threshold AND limit is complex chain.
      
      # Let's use Raw SQL for the whole Step 1 + Distance Select
      # This is safer.
      
      return [] if candidates.empty?
    end

    # Simplified re-implementation of retrieve + process
    def retrieve_candidates(query_embedding, collection_ids)
      Jasmine::DocumentChunk
        .where(collection_id: collection_ids)
        .select("jasmine_document_chunks.*, (embedding <=> '#{query_embedding}') as distance")
        .order("distance ASC")
        .limit(CANDIDATES_PER_PRIORITY)
    end
    
    # Overwrite process_candidates with the list from above
    def process_candidates(candidates)
       filtered = []
       doc_counts = Hash.new(0)
       
       candidates.each do |chunk|
          # 1. Threshold Check
          # distance is a string/float from SQL
          dist = chunk[:distance].to_f
          next if dist > @threshold
          
          # 2. Doc Dedupe
          limit = MAX_CHUNKS_PER_DOC
          next if doc_counts[chunk.document_id] >= limit
          
          doc_counts[chunk.document_id] += 1
          filtered << chunk
       end
       
       # 3. Top K per Priority
       filtered.first(TOP_K_PER_PRIORITY)
    end

    def generate_embedding(text)
      # Using shared logic or direct call. 
      # Duplication for now to keep service independent or use embedding service class func
      model = ENV.fetch('JASMINE_EMBEDDING_MODEL', 'text-embedding-3-small')
      RubyLLM.embed(text, model: model).vectors.first
    end
    
    def to_pg_vector(vector)
      # Ensure vector is an array of floats
      # PGVector accepts JSON array string e.g. "[1.0, 2.0]"
      vector.to_s
    end
  end
end
