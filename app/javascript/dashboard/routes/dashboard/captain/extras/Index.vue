<script setup>
import { onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useRoute } from 'vue-router';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import ExtraModal from './ExtraModal.vue';

const { t } = useI18n();
const extras = ref([]);
const isLoading = ref(false);
const showModal = ref(false);
const showDeleteConfirmation = ref(false);
const extraToDelete = ref(null);
const selectedExtra = ref(null);
const route = useRoute();
const accountId = route.params.accountId;

const openAddModal = () => {
  selectedExtra.value = null;
  showModal.value = true;
};

const openEditModal = extra => {
  selectedExtra.value = extra;
  showModal.value = true;
};

const handleSave = saved => {
  const index = extras.value.findIndex(e => e.id === saved.id);
  if (index !== -1) {
    extras.value[index] = saved;
  } else {
    extras.value.push(saved);
  }
};

const fetchExtras = async () => {
  isLoading.value = true;
  try {
    const { data } = await window.axios.get(
      `/api/v1/accounts/${accountId}/captain/extras`
    );
    extras.value = data;
  } catch (error) {
    useAlert(t('CAPTAIN.EXTRAS.ERRORS.FETCH_FAILED'));
  } finally {
    isLoading.value = false;
  }
};

const confirmDelete = extra => {
  extraToDelete.value = extra;
  showDeleteConfirmation.value = true;
};

const deleteExtra = async () => {
  if (!extraToDelete.value) return;
  try {
    await window.axios.delete(
      `/api/v1/accounts/${accountId}/captain/extras/${extraToDelete.value.id}`
    );
    extras.value = extras.value.filter(e => e.id !== extraToDelete.value.id);
    useAlert(t('CAPTAIN.EXTRAS.SUCCESS.DELETED'));
  } catch (error) {
    useAlert(t('CAPTAIN.EXTRAS.ERRORS.DELETE_FAILED'));
  } finally {
    showDeleteConfirmation.value = false;
    extraToDelete.value = null;
  }
};

onMounted(fetchExtras);
</script>

<template>
  <!-- eslint-disable vue/no-bare-strings-in-template, @intlify/vue-i18n/no-raw-text -->
  <div
    class="flex flex-col h-full w-full bg-slate-50 dark:bg-slate-900 px-8 py-8 overflow-y-auto"
  >
    <div class="flex-1 w-full">
      <div class="flex justify-between items-center mb-6">
        <h1 class="text-2xl font-semibold text-slate-800 dark:text-slate-100">
          Painel Admin de Extras
        </h1>
      </div>

      <div
        class="bg-white dark:bg-slate-800 rounded-lg shadow-sm border border-slate-200 dark:border-slate-700 w-full"
      >
        <div
          class="p-6 border-b border-slate-200 dark:border-slate-700 flex justify-between items-center bg-white dark:bg-slate-800 rounded-t-lg"
        >
          <div class="flex flex-col">
            <h2 class="text-lg font-medium text-slate-800 dark:text-slate-100">
              Extras
            </h2>
            <p class="text-sm text-slate-500 dark:text-slate-400 mt-1">
              Gerenciamento de Itens Extras
            </p>
          </div>
          <Button
            variant="solid"
            size="sm"
            class="flex items-center gap-2"
            @click="openAddModal"
          >
            <i class="i-lucide-plus" />
            Adicionar Novo Extra
          </Button>
        </div>

        <div v-if="isLoading" class="p-8 flex justify-center">
          <Spinner />
        </div>

        <div v-else class="overflow-x-auto">
          <table class="w-full text-left text-sm">
            <thead
              class="bg-slate-50 dark:bg-slate-700/50 text-slate-500 dark:text-slate-300 uppercase font-medium"
            >
              <tr>
                <th class="px-6 py-4">Nome</th>
                <th class="px-6 py-4">Descrição</th>
                <th class="px-6 py-4">Preço</th>
                <th class="px-6 py-4 text-right">Ações</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-200 dark:divide-slate-700">
              <tr
                v-for="extra in extras"
                :key="extra.id"
                class="hover:bg-slate-50 dark:hover:bg-slate-700/30 transition-colors"
              >
                <td
                  class="px-6 py-4 font-medium text-slate-900 dark:text-slate-100"
                >
                  {{ extra.title }}
                </td>
                <td class="px-6 py-4 text-slate-600 dark:text-slate-300">
                  {{ extra.description }}
                </td>
                <td class="px-6 py-4 font-medium text-green-600">
                  R$
                  {{ Number(extra.price).toFixed(2) }}
                </td>
                <td class="px-6 py-4 text-right flex justify-end gap-2">
                  <button
                    class="text-blue-600 hover:text-blue-800 font-medium"
                    @click="openEditModal(extra)"
                  >
                    Editar
                  </button>
                  <button
                    class="text-red-600 hover:text-red-800 font-medium transition-colors"
                    @click="confirmDelete(extra)"
                  >
                    Excluir
                  </button>
                </td>
              </tr>
              <tr v-if="extras.length === 0">
                <td colspan="4" class="px-6 py-8 text-center text-slate-500">
                  Nenhum item extra encontrado
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <ExtraModal
      :show="showModal"
      :extra="selectedExtra"
      @close="showModal = false"
      @save="handleSave"
    />

    <Dialog
      :show="showDeleteConfirmation"
      title="Excluir Extra"
      message="Tem certeza que deseja excluir este item extra?"
      confirm-text="Excluir"
      cancel-text="Cancelar"
      variant="danger"
      @close="showDeleteConfirmation = false"
      @confirm="deleteExtra"
    />
  </div>
</template>
