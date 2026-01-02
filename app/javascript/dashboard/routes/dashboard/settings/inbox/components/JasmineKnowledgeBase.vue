<script>
import JasmineAPI from 'dashboard/api/inbox/jasmine';
import { useAlert } from 'dashboard/composables';

export default {
  props: {
    inboxId: {
      type: [String, Number],
      required: true,
    },
    isTab: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      collections: [],
      isLoading: false,
      showCreateCollectionModal: false,
      newCollectionName: '',
      newCollectionVisibility: 'private',
      expandedCollectionId: null,
      documents: [],
      isLoadingDocs: false,
      newDocTitle: '',
      newDocContent: '',
      isCreatingDoc: false,
      isDeletingDocument: null, // Track which doc is being deleted
    };
  },
  mounted() {
    this.fetchCollections();
  },
  methods: {
    async fetchCollections() {
      this.isLoading = true;
      try {
        const { data } = await JasmineAPI.getCollections();
        this.collections = data;
      } catch (error) {
        useAlert('Failed to load collections');
      } finally {
        this.isLoading = false;
      }
    },
    async createCollection() {
      try {
        await JasmineAPI.createCollection({
          collection: {
            name: this.newCollectionName,
            visibility: this.newCollectionVisibility,
            owner_inbox_id: this.inboxId,
          },
        });
        this.newCollectionName = '';
        this.showCreateCollectionModal = false;
        this.fetchCollections();
        useAlert('Collection created successfully');
      } catch (error) {
        useAlert('Failed to create collection');
      }
    },
    async toggleCollection(collection) {
      if (this.expandedCollectionId === collection.id) {
        this.expandedCollectionId = null;
        this.documents = [];
        return;
      }
      this.expandedCollectionId = collection.id;
      this.fetchDocuments(collection.id);
    },
    async fetchDocuments(collectionId) {
      this.isLoadingDocs = true;
      try {
        const { data } = await JasmineAPI.getDocuments(collectionId);
        this.documents = data;
      } catch (error) {
        useAlert('Failed to load documents');
      } finally {
        this.isLoadingDocs = false;
      }
    },
    async addDocument(collectionId) {
      this.isCreatingDoc = true;
      try {
        await JasmineAPI.uploadDocument(
          collectionId,
          this.newDocContent,
          this.newDocTitle
        );
        this.newDocTitle = '';
        this.newDocContent = '';
        useAlert('Document added! Processing will start shortly.');
        // Refresh docs to show new document
        this.fetchDocuments(collectionId);
      } catch (error) {
        useAlert('Failed to add document');
      } finally {
        this.isCreatingDoc = false;
      }
    },
    async deleteDocument(collectionId, documentId) {
      if (!confirm('Are you sure you want to delete this document?')) return;
      this.isDeletingDocument = documentId;
      try {
        await JasmineAPI.deleteDocument(collectionId, documentId);
        useAlert('Document deleted successfully');
        this.fetchDocuments(collectionId);
      } catch (error) {
        useAlert('Failed to delete document');
      } finally {
        this.isDeletingDocument = null;
      }
    },
    getStatusClass(status) {
      const classes = {
        pending:
          'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400',
        processing:
          'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400',
        indexed:
          'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400',
        failed: 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400',
      };
      return classes[status] || classes.pending;
    },
    isProcessing(status) {
      return status === 'pending' || status === 'processing';
    },
  },
};
</script>

<template>
  <div
    :class="{
      'mt-8 border-t border-slate-100 dark:border-slate-800 pt-8': !isTab,
      '': isTab,
    }"
  >
    <!-- Header -->
    <div class="flex justify-between items-center mb-6">
      <div>
        <h3 class="text-lg font-semibold text-slate-900 dark:text-slate-100">
          Knowledge Base
        </h3>
        <p class="text-sm text-slate-500 dark:text-slate-400">
          Manage knowledge collections for this inbox
        </p>
      </div>
      <woot-button size="small" @click="showCreateCollectionModal = true">
        + New Collection
      </woot-button>
    </div>

    <!-- Loading -->
    <div v-if="isLoading" class="flex items-center justify-center py-12">
      <span class="i-lucide-loader-2 size-6 animate-spin text-slate-400" />
    </div>

    <!-- Collections List -->
    <div v-else class="space-y-4">
      <div
        v-for="collection in collections"
        :key="collection.id"
        class="border border-slate-200 dark:border-slate-700 rounded-lg overflow-hidden"
      >
        <!-- Collection Header -->
        <div
          class="flex items-center justify-between p-4 bg-white dark:bg-slate-900 cursor-pointer hover:bg-slate-50 dark:hover:bg-slate-800/50"
          @click="toggleCollection(collection)"
        >
          <div class="flex items-center gap-3">
            <span
              :class="[
                'i-lucide-chevron-right size-4 transition-transform text-slate-400',
                expandedCollectionId === collection.id ? 'rotate-90' : '',
              ]"
            />
            <div>
              <h4 class="font-medium text-slate-800 dark:text-slate-200">
                {{ collection.name }}
              </h4>
              <span
                class="text-xs uppercase tracking-wide px-1.5 py-0.5 rounded bg-slate-100 dark:bg-slate-800 text-slate-500"
              >
                {{ collection.visibility }}
              </span>
            </div>
          </div>
        </div>

        <!-- Expanded: Documents -->
        <div
          v-if="expandedCollectionId === collection.id"
          class="border-t border-slate-100 dark:border-slate-700 bg-slate-50 dark:bg-slate-800/30 p-4"
        >
          <h5 class="text-xs font-semibold uppercase text-slate-500 mb-3">
            Documents
          </h5>

          <!-- Loading Documents -->
          <div
            v-if="isLoadingDocs"
            class="flex items-center gap-2 text-sm text-slate-400 py-2"
          >
            <span class="i-lucide-loader-2 size-4 animate-spin" />
            Loading documents...
          </div>

          <!-- Documents List -->
          <div v-else class="space-y-2 mb-4">
            <div
              v-for="doc in documents"
              :key="doc.id"
              class="flex items-center justify-between p-3 bg-white dark:bg-slate-900 rounded-lg border border-slate-200 dark:border-slate-700"
            >
              <div class="flex items-center gap-3 min-w-0 flex-1">
                <span
                  class="i-lucide-file-text size-4 text-slate-400 shrink-0"
                />
                <div class="min-w-0">
                  <p
                    class="font-medium text-sm text-slate-800 dark:text-slate-200 truncate"
                  >
                    {{ doc.title || 'Untitled Document' }}
                  </p>
                  <p class="text-xs text-slate-400 truncate">
                    {{ new Date(doc.created_at).toLocaleDateString() }}
                  </p>
                </div>
              </div>
              <div class="flex items-center gap-3 shrink-0">
                <!-- Status Badge -->
                <span
                  :class="[
                    'inline-flex items-center gap-1 px-2 py-0.5 text-xs font-medium rounded-full',
                    getStatusClass(doc.status),
                  ]"
                >
                  <span
                    v-if="isProcessing(doc.status)"
                    class="i-lucide-loader-2 size-3 animate-spin"
                  />
                  {{ doc.status || 'pending' }}
                </span>
                <!-- Delete Button -->
                <button
                  class="p-1.5 rounded hover:bg-red-50 dark:hover:bg-red-900/20 text-slate-400 hover:text-red-500 transition-colors"
                  :disabled="isDeletingDocument === doc.id"
                  @click.stop="deleteDocument(collection.id, doc.id)"
                >
                  <span
                    v-if="isDeletingDocument === doc.id"
                    class="i-lucide-loader-2 size-4 animate-spin"
                  />
                  <span v-else class="i-lucide-trash-2 size-4" />
                </button>
              </div>
            </div>

            <div
              v-if="documents.length === 0"
              class="text-center py-6 text-sm text-slate-400"
            >
              No documents yet. Add your first document below.
            </div>
          </div>

          <!-- Add Document Form -->
          <div
            class="border-t border-slate-200 dark:border-slate-700 pt-4 mt-4"
          >
            <h6 class="text-xs font-semibold uppercase text-slate-500 mb-3">
              Add New Document
            </h6>
            <input
              v-model="newDocTitle"
              type="text"
              class="w-full mb-2 px-3 py-2 text-sm rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900"
              placeholder="Document title (optional)"
            />
            <textarea
              v-model="newDocContent"
              rows="4"
              class="w-full mb-3 px-3 py-2 text-sm rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 resize-none"
              placeholder="Paste or type your knowledge content here..."
            />
            <div class="flex justify-end">
              <woot-button
                size="small"
                :is-loading="isCreatingDoc"
                :disabled="!newDocContent.trim()"
                @click="addDocument(collection.id)"
              >
                Add Document
              </woot-button>
            </div>
          </div>
        </div>
      </div>

      <!-- Empty State -->
      <div
        v-if="collections.length === 0"
        class="text-center py-12 text-slate-400"
      >
        <span class="i-lucide-folder-open size-12 mx-auto mb-3 opacity-50" />
        <p class="text-sm">No collections yet. Create one to get started.</p>
      </div>
    </div>

    <!-- Create Collection Modal -->
    <div
      v-if="showCreateCollectionModal"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/50"
      @click.self="showCreateCollectionModal = false"
    >
      <div class="bg-white dark:bg-slate-900 p-6 rounded-xl w-96 shadow-2xl">
        <h3 class="text-lg font-semibold mb-4 text-slate-900 dark:text-white">
          Create Collection
        </h3>
        <input
          v-model="newCollectionName"
          type="text"
          class="w-full mb-4 px-3 py-2 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800"
          placeholder="Collection name"
          @keyup.enter="createCollection"
        />
        <select
          v-model="newCollectionVisibility"
          class="w-full mb-4 px-3 py-2 rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800"
        >
          <option value="private">Private (This inbox only)</option>
          <option value="shared">Shared (All inboxes)</option>
        </select>
        <div class="flex justify-end gap-2">
          <woot-button
            variant="clear"
            @click="showCreateCollectionModal = false"
          >
            Cancel
          </woot-button>
          <woot-button
            :disabled="!newCollectionName.trim()"
            @click="createCollection"
          >
            Create
          </woot-button>
        </div>
      </div>
    </div>
  </div>
</template>
