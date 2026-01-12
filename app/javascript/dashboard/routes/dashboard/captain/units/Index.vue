<script setup>
import { onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useRoute } from 'vue-router';
import UnitModal from './UnitModal.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const units = ref([]);
const isLoading = ref(false);
const showModal = ref(false);
const selectedUnit = ref(null);
const route = useRoute();
const { t } = useI18n();
const accountId = route.params.accountId;

const openAddUnitModal = () => {
  selectedUnit.value = null;
  showModal.value = true;
};

const openEditModal = unit => {
  selectedUnit.value = unit;
  showModal.value = true;
};

const handleSave = savedUnit => {
  const index = units.value.findIndex(u => u.id === savedUnit.id);
  if (index !== -1) {
    units.value[index] = savedUnit;
  } else {
    units.value.push(savedUnit);
  }
};

const fetchUnits = async () => {
  isLoading.value = true;
  try {
    const { data } = await window.axios.get(
      `/api/v1/accounts/${accountId}/captain/units?all=true`
    );
    units.value = data;
  } catch (error) {
    useAlert(t('CAPTAIN.UNITS.ERROR_FETCHING'));
  } finally {
    isLoading.value = false;
  }
};

const toggleStatus = async unit => {
  const newStatus = unit.status === 'active' ? 'inactive' : 'active';
  try {
    await window.axios.put(
      `/api/v1/accounts/${accountId}/captain/units/${unit.id}`,
      {
        unit: { status: newStatus },
      }
    );
    unit.status = newStatus;
    useAlert(t('CAPTAIN.UNITS.UPDATE_SUCCESS'));
  } catch (error) {
    useAlert(t('CAPTAIN.UNITS.UPDATE_ERROR'));
  }
};

const getPublicPageURL = () => {
  return `${window.location.origin}/public/accounts/${accountId}/reservas`;
};

const copyPublicLink = async () => {
  try {
    await navigator.clipboard.writeText(getPublicPageURL());
    useAlert(t('CAPTAIN.UNITS.COPY_LINK_SUCCESS'));
  } catch (err) {
    useAlert(t('CAPTAIN.UNITS.COPY_LINK_ERROR'));
  }
};

const openPublicPage = () => {
  window.open(getPublicPageURL(), '_blank');
};

/*
const deleteUnit = async unitId => {
  if (!confirm('Tem certeza que deseja excluir esta unidade?')) return;

  try {
    await window.axios.delete(
      `/api/v1/accounts/${accountId}/captain/units/${unitId}`
    );
    units.value = units.value.filter(u => u.id !== unitId);
    useAlert('Unidade excluída com sucesso');
  } catch (error) {
    useAlert('Erro ao excluir unidade');
  }
};
*/

onMounted(fetchUnits);
</script>

<template>
  <!-- eslint-disable vue/no-bare-strings-in-template -->
  <!-- eslint-disable vue/no-bare-strings-in-template -->
  <div
    class="flex flex-col h-full w-full bg-slate-50 dark:bg-slate-900 px-8 py-8 overflow-y-auto"
  >
    <div class="flex-1 w-full">
      <div class="flex justify-between items-center mb-6">
        <h1 class="text-2xl font-semibold text-slate-800 dark:text-slate-100">
          Painel Administrativo
        </h1>
        <div class="flex gap-2">
          <Button
            variant="outline"
            color="slate"
            size="sm"
            icon="link"
            @click="copyPublicLink"
          >
            {{ $t('CAPTAIN.UNITS.COPY_LINK') }}
          </Button>
          <Button
            variant="outline"
            color="slate"
            size="sm"
            icon="arrow-up-right"
            @click="openPublicPage"
          >
            {{ $t('CAPTAIN.UNITS.OPEN_PAGE') }}
          </Button>
        </div>
      </div>

      <div
        class="bg-white dark:bg-slate-800 rounded-lg shadow-sm border border-slate-200 dark:border-slate-700 w-full"
      >
        <div
          class="p-6 border-b border-slate-200 dark:border-slate-700 flex justify-between items-center bg-white dark:bg-slate-800 rounded-t-lg"
        >
          <h2 class="text-lg font-medium text-slate-800 dark:text-slate-100">
            {{ $t('CAPTAIN.UNITS.HEADER') }}
          </h2>
          <Button
            variant="solid"
            size="sm"
            class="flex items-center gap-2"
            @click="openAddUnitModal"
          >
            <i class="i-lucide-plus" />
            {{ $t('CAPTAIN.UNITS.ADD_NEW') }}
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
                <th class="px-6 py-4">Nome da Unidade</th>
                <th class="px-6 py-4">Status</th>
                <th class="px-6 py-4 text-right">Ações</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-200 dark:divide-slate-700">
              <tr
                v-for="unit in units"
                :key="unit.id"
                class="hover:bg-slate-50 dark:hover:bg-slate-700/30 transition-colors"
              >
                <td
                  class="px-6 py-4 font-medium text-slate-900 dark:text-slate-100"
                >
                  <div class="flex flex-col">
                    <span>{{ unit.name }}</span>
                    <span class="text-xs text-slate-500 dark:text-slate-400">
                      ID: {{ unit.id }}
                    </span>
                  </div>
                </td>
                <td class="px-6 py-4">
                  <span
                    class="px-2 py-1 text-xs font-medium rounded-full"
                    :class="{
                      'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300':
                        unit.status === 'active',
                      'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300':
                        unit.status === 'inactive',
                    }"
                  >
                    {{ unit.status === 'active' ? 'Ativo' : 'Inativo' }}
                  </span>
                </td>
                <td class="px-6 py-4 text-right flex justify-end gap-2">
                  <button
                    class="text-blue-600 hover:text-blue-800 font-medium"
                    @click="openEditModal(unit)"
                  >
                    Editar
                  </button>
                  <button
                    class="text-slate-600 hover:text-slate-800 font-medium transition-colors"
                    @click="toggleStatus(unit)"
                  >
                    {{ unit.status === 'active' ? 'Desativar' : 'Ativar' }}
                  </button>
                </td>
              </tr>
              <tr v-if="units.length === 0">
                <td colspan="3" class="px-6 py-8 text-center text-slate-500">
                  Nenhuma unidade cadastrada.
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <UnitModal
      :show="showModal"
      :unit="selectedUnit"
      @close="showModal = false"
      @save="handleSave"
    />
  </div>
</template>
