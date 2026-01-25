class CreateJasmineTables < ActiveRecord::Migration[7.1]
  def change
    # 1. Jasmine Inbox Settings
    create_table :jasmine_inbox_settings do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :inbox, null: false, foreign_key: true, index: true
      t.string :name, default: 'Jasmine'
      t.text :system_prompt
      t.boolean :is_enabled, default: false
      t.integer :mode, default: 0 # 0=copilot, 1=autopilot

      t.timestamps
    end
    add_index :jasmine_inbox_settings, [:account_id, :inbox_id], unique: true

    # 2. Jasmine Collections
    create_table :jasmine_collections do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.text :description
      # Owner inbox is optional (nullable), but if present, must exist in inboxes table
      t.references :owner_inbox, null: true, foreign_key: { to_table: :inboxes }
      t.integer :visibility, default: 0 # 0=private, 1=shared, 2=global
      t.boolean :is_active, default: true

      t.timestamps
    end
    add_index :jasmine_collections, [:account_id, :visibility]
    add_index :jasmine_collections, [:account_id, :owner_inbox_id]

    # 3. Jasmine Inbox Collections (Pivot)
    create_table :jasmine_inbox_collections do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :inbox, null: false, foreign_key: true, index: true
      t.references :collection, null: false, foreign_key: { to_table: :jasmine_collections }, index: true
      t.boolean :is_enabled, default: true
      t.integer :priority, default: 0

      t.timestamps
    end
    add_index :jasmine_inbox_collections, [:account_id, :inbox_id, :collection_id], unique: true, name: 'index_jasmine_inbox_collections_uniqueness'
    add_index :jasmine_inbox_collections, [:account_id, :inbox_id]
    add_index :jasmine_inbox_collections, [:account_id, :collection_id]

    # 4. Jasmine Documents
    create_table :jasmine_documents do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :collection, null: false, foreign_key: { to_table: :jasmine_collections }, index: true
      t.string :title
      t.text :content
      t.jsonb :metadata, default: {}
      t.integer :source_type, default: 0 # 0=manual, 1=upload, 2=url, 3=faq
      t.integer :status, default: 0 # 0=pending, 1=processing, 2=indexed, 3=failed
      t.text :error_message

      t.timestamps
    end
    add_index :jasmine_documents, [:account_id, :collection_id, :status], name: 'index_jasmine_docs_on_acc_coll_status'

    # 5. Jasmine Document Chunks (Vector Store)
    create_table :jasmine_document_chunks do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :collection, null: false, foreign_key: { to_table: :jasmine_collections }, index: true
      t.references :document, null: false, foreign_key: { to_table: :jasmine_documents }, index: true
      t.text :content
      t.jsonb :metadata, default: {} # chunk_index, char_start, char_end
      t.vector :embedding, limit: 1536 # Using vector type from pgvector

      t.timestamps
    end
    add_index :jasmine_document_chunks, [:account_id, :collection_id, :document_id], name: 'index_jasmine_chunks_on_acc_coll_doc'

    # HNSW Index for Vector Search (Cosine Distance)
    # Ensure pgvector extension is enabled in a previous migration or here if needed,
    # but based on plan it is already enabled.
    add_index :jasmine_document_chunks, :embedding, using: :hnsw, opclass: :vector_cosine_ops
  end
end
