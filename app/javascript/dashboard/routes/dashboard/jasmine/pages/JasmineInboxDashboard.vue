<script setup>
import { ref, reactive, computed, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import JasmineAPI from 'dashboard/api/inbox/jasmine';

import SettingsLayout from 'dashboard/routes/dashboard/settings/SettingsLayout.vue';
import BaseSettingsHeader from 'dashboard/routes/dashboard/settings/components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import JasmineToolsTab from '../components/JasmineToolsTab.vue';

const route = useRoute();
const store = useStore();
const getters = useStoreGetters();

// State
const activeTab = ref('knowledge');
const collections = ref([]);
const isLoading = ref(false);
const expandedCollectionId = ref(null);
const documents = ref([]);
const isLoadingDocs = ref(false);
const isDeletingDoc = ref(null);
const isDeletingCollection = ref(null);

// Form state
const showCreateModal = ref(false);
const newCollectionName = ref('');
const newCollectionVisibility = ref('private');
const newDocTitle = ref('');
const newDocContent = ref('');
const isCreatingDoc = ref(false);

// Edit state
const showEditDocModal = ref(false);
const editingDoc = ref(null);
const editDocTitle = ref('');
const editDocContent = ref('');

// Config state
const config = ref({
  is_enabled: false,
  system_prompt: '',
  playbook_prompt: '',
  model: 'gpt-4o-mini',
  temperature: 0.7,
  rag_distance_threshold: 0.35,
  rag_max_results: 3,
});
const isLoadingConfig = ref(false);
const isSavingConfig = ref(false);

const expandedFields = reactive({
  system_prompt: false,
  playbook_prompt: false,
});

// Computed
const inboxId = computed(() => Number(route.params.inboxId));
const inbox = computed(() => getters['inboxes/getInbox'].value(inboxId.value));
const inboxName = computed(() => inbox.value?.name || 'Loading...');

const tabs = [
  { key: 'knowledge', label: 'Base de Conhecimento' },
  { key: 'config', label: 'Configuração' },
  { key: 'tools', label: 'Ferramentas' },
];

// Methods
const fetchCollections = async () => {
  isLoading.value = true;
  try {
    const { data } = await JasmineAPI.getCollections();
    collections.value = data;
  } catch (error) {
    useAlert('Failed to load collections');
  } finally {
    isLoading.value = false;
  }
};

const createCollection = async () => {
  if (!newCollectionName.value.trim()) return;
  try {
    await JasmineAPI.createCollection({
      collection: {
        name: newCollectionName.value,
        visibility: newCollectionVisibility.value,
        owner_inbox_id: inboxId.value,
      },
    });
    newCollectionName.value = '';
    showCreateModal.value = false;
    fetchCollections();
    useAlert('Collection created successfully');
  } catch (error) {
    useAlert('Failed to create collection');
  }
};

const deleteCollection = async collectionId => {
  if (!confirm('Delete this collection and all its documents?')) return;
  isDeletingCollection.value = collectionId;
  try {
    await JasmineAPI.deleteCollection(collectionId);
    useAlert('Collection deleted');
    fetchCollections();
  } catch (error) {
    useAlert('Failed to delete collection');
  } finally {
    isDeletingCollection.value = null;
  }
};

const toggleCollection = async collection => {
  if (expandedCollectionId.value === collection.id) {
    expandedCollectionId.value = null;
    documents.value = [];
    return;
  }
  expandedCollectionId.value = collection.id;
  await fetchDocuments(collection.id);
};

const fetchDocuments = async collectionId => {
  isLoadingDocs.value = true;
  try {
    const { data } = await JasmineAPI.getDocuments(collectionId);
    documents.value = data;
  } catch (error) {
    useAlert('Failed to load documents');
  } finally {
    isLoadingDocs.value = false;
  }
};

const addDocument = async collectionId => {
  if (!newDocContent.value.trim()) return;
  isCreatingDoc.value = true;
  try {
    await JasmineAPI.uploadDocument(
      collectionId,
      newDocContent.value,
      newDocTitle.value
    );
    newDocTitle.value = '';
    newDocContent.value = '';
    useAlert('Document added! Processing will start shortly.');
    fetchDocuments(collectionId);
  } catch (error) {
    useAlert('Failed to add document');
  } finally {
    isCreatingDoc.value = false;
  }
};

const deleteDocument = async (collectionId, docId) => {
  if (!confirm('Delete this document?')) return;
  isDeletingDoc.value = docId;
  try {
    await JasmineAPI.deleteDocument(collectionId, docId);
    useAlert('Document deleted');
    fetchDocuments(collectionId);
  } catch (error) {
    useAlert('Failed to delete document');
  } finally {
    isDeletingDoc.value = null;
  }
};

const openEditDoc = doc => {
  editingDoc.value = doc;
  editDocTitle.value = doc.title || '';
  editDocContent.value = doc.content || '';
  showEditDocModal.value = true;
};

const saveEditDoc = async () => {
  // TODO: Implement update API when available
  useAlert('Edit functionality coming soon');
  showEditDocModal.value = false;
};

const getStatusColor = status => {
  const colors = {
    indexed:
      'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400',
    pending:
      'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400',
    processing:
      'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400',
    failed: 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400',
  };
  return colors[status] || colors.pending;
};

const fetchConfig = async () => {
  isLoadingConfig.value = true;
  try {
    const { data } = await JasmineAPI.getSettings(inboxId.value);
    config.value = {
      is_enabled: data.is_enabled || false,
      system_prompt: data.system_prompt || '',
      playbook_prompt: data.playbook_prompt || '',
      model: data.model || 'gpt-4o-mini',
      temperature: data.temperature || 0.7,
      rag_distance_threshold: data.rag_distance_threshold || 0.35,
      rag_max_results: data.rag_max_results || 3,
    };
  } catch (error) {
    // Config may not exist yet, use defaults
    console.log('No config found, using defaults');
  } finally {
    isLoadingConfig.value = false;
  }
};

const saveConfig = async () => {
  isSavingConfig.value = true;
  try {
    await JasmineAPI.updateSettings(inboxId.value, config.value);
    useAlert('Configuração salva com sucesso!');
  } catch (error) {
    isSavingConfig.value = false;
  }
};

const toggleExpand = field => {
  if (field === 'system_prompt') {
    expandedFields.system_prompt = !expandedFields.system_prompt;
  } else if (field === 'playbook_prompt') {
    expandedFields.playbook_prompt = !expandedFields.playbook_prompt;
  }
};

onMounted(() => {
  fetchCollections();
  fetchConfig();
});
</script>

<template>
  <SettingsLayout :is-loading="false">
    <template #header>
      <BaseSettingsHeader
        :title="inboxName"
        description="Gerencie a base de conhecimento e configurações do Jasmine AI para esta caixa de entrada"
        back-button-label="Voltar para Caixas"
      >
        <template #actions>
          <Button
            v-if="activeTab === 'knowledge'"
            icon="i-lucide-circle-plus"
            label="Nova Coleção"
            @click="showCreateModal = true"
          />
        </template>
      </BaseSettingsHeader>
    </template>

    <template #body>
      <!-- Tabs -->
      <div class="flex gap-1 p-1 mb-6 rounded-lg bg-n-alpha-1 w-fit mx-auto">
        <button
          v-for="tab in tabs"
          :key="tab.key"
          :class="[
            'px-4 py-2 text-sm font-medium rounded-md transition-colors',
            activeTab === tab.key
              ? 'bg-n-solid-1 text-n-slate-12 shadow-sm'
              : 'text-n-slate-11 hover:text-n-slate-12',
          ]"
          @click="activeTab = tab.key"
        >
          {{ tab.label }}
        </button>
      </div>

      <!-- Knowledge Base Tab -->
      <div v-if="activeTab === 'knowledge'">
        <!-- Loading -->
        <div v-if="isLoading" class="flex items-center justify-center py-12">
          <woot-loading-state message="Carregando coleções..." />
        </div>

        <!-- Collections Table -->
        <div v-else>
          <table
            v-if="collections.length"
            class="min-w-full divide-y divide-n-weak"
          >
            <thead>
              <tr>
                <th
                  class="py-3 text-left text-sm font-semibold text-n-slate-11"
                >
                  Coleção
                </th>
                <th
                  class="py-3 text-left text-sm font-semibold text-n-slate-11"
                >
                  Visibilidade
                </th>
                <th
                  class="py-3 text-left text-sm font-semibold text-n-slate-11"
                >
                  Documentos
                </th>
                <th
                  class="py-3 text-right text-sm font-semibold text-n-slate-11"
                >
                  Ações
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-n-weak">
              <template v-for="collection in collections" :key="collection.id">
                <tr class="hover:bg-n-alpha-1 transition-colors">
                  <td class="py-4 text-n-slate-12 font-medium">
                    {{ collection.name }}
                  </td>
                  <td class="py-4">
                    <span
                      :class="[
                        'px-2 py-1 text-xs font-medium rounded uppercase',
                        collection.visibility === 'private'
                          ? 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400'
                          : 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400',
                      ]"
                    >
                      {{ collection.visibility }}
                    </span>
                  </td>
                  <td class="py-4 text-n-slate-11">-</td>
                  <td class="py-4">
                    <div class="flex justify-end gap-1">
                      <Button
                        v-tooltip.top="
                          expandedCollectionId === collection.id
                            ? 'Close'
                            : 'Manage Documents'
                        "
                        :icon="
                          expandedCollectionId === collection.id
                            ? 'i-lucide-chevron-up'
                            : 'i-lucide-chevron-down'
                        "
                        slate
                        xs
                        faded
                        @click="toggleCollection(collection)"
                      />
                      <Button
                        v-tooltip.top="'Delete Collection'"
                        icon="i-lucide-trash-2"
                        ruby
                        xs
                        faded
                        :is-loading="isDeletingCollection === collection.id"
                        @click="deleteCollection(collection.id)"
                      />
                    </div>
                  </td>
                </tr>
                <!-- Expanded Documents Panel -->
                <tr v-if="expandedCollectionId === collection.id">
                  <td colspan="4" class="p-0">
                    <div class="bg-n-alpha-1 p-4 border-t border-n-weak">
                      <h4 class="text-sm font-semibold text-n-slate-11 mb-4">
                        Documents
                      </h4>

                      <!-- Loading Docs -->
                      <div
                        v-if="isLoadingDocs"
                        class="text-sm text-n-slate-11 py-2"
                      >
                        Loading documents...
                      </div>

                      <!-- Documents List -->
                      <div v-else class="space-y-2 mb-4">
                        <div
                          v-for="doc in documents"
                          :key="doc.id"
                          class="flex items-center justify-between p-3 bg-n-solid-1 rounded-lg border border-n-weak cursor-pointer hover:border-n-blue-7 transition-colors"
                          @click="openEditDoc(doc)"
                        >
                          <div class="flex items-center gap-3 min-w-0 flex-1">
                            <div class="min-w-0">
                              <p
                                class="font-medium text-sm text-n-slate-12 truncate"
                              >
                                {{ doc.title || 'Untitled Document' }}
                              </p>
                              <p class="text-xs text-n-slate-11">
                                {{
                                  new Date(doc.created_at).toLocaleDateString()
                                }}
                              </p>
                            </div>
                          </div>
                          <div class="flex items-center gap-2 shrink-0">
                            <span
                              :class="[
                                'px-2 py-0.5 text-xs font-medium rounded-full',
                                getStatusColor(doc.status),
                              ]"
                            >
                              {{ doc.status || 'pending' }}
                            </span>
                            <Button
                              v-tooltip.top="'Delete'"
                              icon="i-lucide-trash-2"
                              xs
                              ruby
                              faded
                              :is-loading="isDeletingDoc === doc.id"
                              @click.stop="
                                deleteDocument(collection.id, doc.id)
                              "
                            />
                          </div>
                        </div>
                        <p
                          v-if="!documents.length"
                          class="text-sm text-n-slate-11 italic py-4 text-center"
                        >
                          Nenhum documento ainda. Adicione o primeiro abaixo.
                        </p>
                      </div>

                      <!-- Add Document Form -->
                      <div class="border-t border-n-weak pt-4 mt-4">
                        <h5
                          class="text-xs font-semibold uppercase text-n-slate-11 mb-3"
                        >
                          Adicionar Novo Documento
                        </h5>
                        <input
                          v-model="newDocTitle"
                          type="text"
                          class="w-full mb-2 px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-solid-1 text-n-slate-12"
                          placeholder="Título do documento (opcional)"
                        />
                        <textarea
                          v-model="newDocContent"
                          rows="4"
                          class="w-full mb-3 px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-solid-1 text-n-slate-12 resize-none"
                          placeholder="Cole ou digite o conteúdo do conhecimento aqui..."
                        />
                        <div class="flex justify-end">
                          <Button
                            label="Adicionar Documento"
                            icon="i-lucide-plus"
                            :disabled="!newDocContent.trim()"
                            :is-loading="isCreatingDoc"
                            @click="addDocument(collection.id)"
                          />
                        </div>
                      </div>
                    </div>
                  </td>
                </tr>
              </template>
            </tbody>
          </table>

          <!-- Empty State -->
          <div v-else class="text-center py-12 text-n-slate-11">
            <p class="mb-4">Nenhuma coleção ainda. Crie uma para começar.</p>
            <Button
              icon="i-lucide-circle-plus"
              label="Criar Primeira Coleção"
              @click="showCreateModal = true"
            />
          </div>
        </div>
      </div>

      <!-- Configuration Tab -->
      <div v-if="activeTab === 'config'" class="max-w-3xl mx-auto">
        <div
          v-if="isLoadingConfig"
          class="flex items-center justify-center py-12"
        >
          <woot-loading-state message="Carregando configurações..." />
        </div>

        <div v-else class="space-y-6">
          <!-- Enable Toggle -->
          <div
            class="flex items-center justify-between p-4 bg-n-alpha-2 rounded-lg"
          >
            <div>
              <h4 class="text-sm font-medium text-n-slate-12">
                Ativar Jasmine AI
              </h4>
              <p class="text-xs text-n-slate-11">
                Quando ativado, Jasmine responderá automaticamente às mensagens
              </p>
            </div>
            <label class="relative inline-flex items-center cursor-pointer">
              <input
                v-model="config.is_enabled"
                type="checkbox"
                class="sr-only peer"
              />
              <div
                class="w-11 h-6 bg-n-slate-6 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-n-blue-9"
              />
            </label>
          </div>

          <!-- System Prompt -->
          <div>
            <div class="flex items-center justify-between mb-2">
              <div>
                <label class="block text-sm font-medium text-n-slate-12"
                  >System Prompt</label
                >
                <p class="text-xs text-n-slate-11">
                  Identidade e regras gerais da Jasmine
                </p>
              </div>
              <Button
                type="button"
                v-tooltip="
                  expandedFields.system_prompt ? 'Recolher' : 'Expandir'
                "
                :icon="
                  expandedFields.system_prompt
                    ? 'i-lucide-minimize-2'
                    : 'i-lucide-maximize-2'
                "
                xs
                faded
                slate
                @click="toggleExpand('system_prompt')"
              />
            </div>
            <textarea
              v-model="config.system_prompt"
              :class="[
                'w-full px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-solid-1 text-n-slate-12 resize-none font-mono transition-all duration-300',
                expandedFields.system_prompt ? 'h-[600px]' : 'h-32',
              ]"
              placeholder="Você é Jasmine, uma assistente virtual da [Empresa]..."
            />
          </div>

          <!-- Playbook SDR -->
          <div>
            <div class="flex items-center justify-between mb-2">
              <div>
                <label class="block text-sm font-medium text-n-slate-12"
                  >Playbook SDR</label
                >
                <p class="text-xs text-n-slate-11">
                  Script de vendas e tratamento de objeções
                </p>
              </div>
              <Button
                type="button"
                v-tooltip="
                  expandedFields.playbook_prompt ? 'Recolher' : 'Expandir'
                "
                :icon="
                  expandedFields.playbook_prompt
                    ? 'i-lucide-minimize-2'
                    : 'i-lucide-maximize-2'
                "
                xs
                faded
                slate
                @click="toggleExpand('playbook_prompt')"
              />
            </div>
            <textarea
              v-model="config.playbook_prompt"
              :class="[
                'w-full px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-solid-1 text-n-slate-12 resize-none font-mono transition-all duration-300',
                expandedFields.playbook_prompt ? 'h-[600px]' : 'h-48',
              ]"
              placeholder="## Objetivo\nQualificar leads...\n\n## Perguntas...\n\n## Objeções..."
            />
          </div>

          <!-- Model Settings -->
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-n-slate-12 mb-2"
                >Modelo LLM</label
              >
              <select
                v-model="config.model"
                class="w-full px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-solid-1 text-n-slate-12"
              >
                <option value="gpt-4o-mini">
                  GPT-4o Mini (rápido, econômico)
                </option>
                <option value="gpt-4o">GPT-4o (mais inteligente)</option>
                <option value="gpt-4-turbo">GPT-4 Turbo</option>
                <option value="claude-3-5-sonnet-20241022">
                  Claude 3.5 Sonnet
                </option>
              </select>
            </div>
            <div>
              <label class="block text-sm font-medium text-n-slate-12 mb-2"
                >Temperatura: {{ config.temperature }}</label
              >
              <input
                v-model.number="config.temperature"
                type="range"
                min="0"
                max="1"
                step="0.1"
                class="w-full h-2 bg-n-slate-6 rounded-lg appearance-none cursor-pointer"
              />
              <p class="text-xs text-n-slate-11 mt-1">
                Menor = mais preciso, Maior = mais criativo
              </p>
            </div>
          </div>

          <!-- RAG Settings -->
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-n-slate-12 mb-2"
                >Threshold de Distância:
                {{ config.rag_distance_threshold }}</label
              >
              <input
                v-model.number="config.rag_distance_threshold"
                type="range"
                min="0.1"
                max="0.8"
                step="0.05"
                class="w-full h-2 bg-n-slate-6 rounded-lg appearance-none cursor-pointer"
              />
              <p class="text-xs text-n-slate-11 mt-1">
                Menor = mais preciso, Maior = mais resultados
              </p>
            </div>
            <div>
              <label class="block text-sm font-medium text-n-slate-12 mb-2"
                >Máx. Resultados RAG</label
              >
              <input
                v-model.number="config.rag_max_results"
                type="number"
                min="1"
                max="10"
                class="w-full px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-solid-1 text-n-slate-12"
              />
            </div>
          </div>

          <!-- Save Button -->
          <div class="flex justify-end pt-4 border-t border-n-weak">
            <Button
              label="Salvar Configurações"
              icon="i-lucide-save"
              :is-loading="isSavingConfig"
              @click="saveConfig"
            />
          </div>
        </div>
      </div>
      <!-- Tools Tab -->
      <JasmineToolsTab v-if="activeTab === 'tools'" :inbox-id="inboxId" />
    </template>

    <!-- Create Collection Modal -->
    <woot-modal
      v-model:show="showCreateModal"
      :on-close="() => (showCreateModal = false)"
    >
      <div class="flex flex-col h-auto overflow-auto p-6">
        <h3 class="text-lg font-semibold mb-4 text-n-slate-12">
          Criar Coleção
        </h3>
        <input
          v-model="newCollectionName"
          type="text"
          class="w-full mb-4 px-3 py-2 rounded-lg border border-n-weak bg-n-solid-1 text-n-slate-12"
          placeholder="Nome da coleção"
          @keyup.enter="createCollection"
        />
        <select
          v-model="newCollectionVisibility"
          class="w-full mb-4 px-3 py-2 rounded-lg border border-n-weak bg-n-solid-1 text-n-slate-12"
        >
          <option value="private">Privada (Somente esta caixa)</option>
          <option value="shared">Compartilhada (Todas as caixas)</option>
        </select>
        <div class="flex justify-end gap-2">
          <Button
            slate
            faded
            label="Cancelar"
            @click="showCreateModal = false"
          />
          <Button
            label="Criar"
            :disabled="!newCollectionName.trim()"
            @click="createCollection"
          />
        </div>
      </div>
    </woot-modal>

    <!-- Edit Document Modal -->
    <woot-modal
      v-model:show="showEditDocModal"
      :on-close="() => (showEditDocModal = false)"
    >
      <div
        class="flex flex-col h-auto overflow-auto p-6"
        style="min-width: 500px"
      >
        <h3 class="text-lg font-semibold mb-4 text-n-slate-12">
          Visualizar Documento
        </h3>
        <input
          v-model="editDocTitle"
          type="text"
          class="w-full mb-4 px-3 py-2 rounded-lg border border-n-weak bg-n-solid-1 text-n-slate-12"
          placeholder="Título do documento"
          disabled
        />
        <textarea
          v-model="editDocContent"
          rows="10"
          class="w-full mb-4 px-3 py-2 rounded-lg border border-n-weak bg-n-solid-1 text-n-slate-12 resize-none"
          disabled
        />
        <div class="flex justify-end gap-2">
          <Button
            slate
            faded
            label="Fechar"
            @click="showEditDocModal = false"
          />
        </div>
      </div>
    </woot-modal>
  </SettingsLayout>
</template>
