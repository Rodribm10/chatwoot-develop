<script setup>
import { onMounted, ref } from 'vue';
import { useAlert } from 'dashboard/composables';
import { useRoute } from 'vue-router';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import PricingModal from './PricingModal.vue';

const pricings = ref([]);
const brands = ref([]);
const isLoading = ref(false);
const showModal = ref(false);
const selectedPricing = ref(null);
const route = useRoute();
const accountId = route.params.accountId;

const openAddModal = () => {
  selectedPricing.value = {};
  showModal.value = true;
};

const openEditModal = pricing => {
  selectedPricing.value = pricing;
  showModal.value = true;
};

const handleSave = saved => {
  const index = pricings.value.findIndex(p => p.id === saved.id);
  if (index !== -1) {
    pricings.value[index] = saved;
  } else {
    pricings.value.push(saved);
  }
};

const fetchData = async () => {
  isLoading.value = true;
  try {
    const [pricesRes, brandsRes] = await Promise.all([
      window.axios.get(`/api/v1/accounts/${accountId}/captain/pricings`),
      window.axios.get(`/api/v1/accounts/${accountId}/captain/brands`),
    ]);
    pricings.value = pricesRes.data;
    brands.value = brandsRes.data;
  } catch (error) {
    useAlert('Erro ao buscar dados');
  } finally {
    isLoading.value = false;
  }
};

const deletePricing = async pricing => {
  // eslint-disable-next-line no-alert, no-restricted-globals
  if (!confirm('Tem certeza que deseja excluir esta regra?')) return;
  try {
    await window.axios.delete(
      `/api/v1/accounts/${accountId}/captain/pricings/${pricing.id}`
    );
    pricings.value = pricings.value.filter(p => p.id !== pricing.id);
    useAlert('Regra removida');
  } catch (error) {
    useAlert('Erro ao remover regra');
  }
};

onMounted(fetchData);
</script>

<template>
  <!-- eslint-disable vue/no-bare-strings-in-template -->
  <div
    class="flex flex-col h-full w-full bg-slate-50 dark:bg-slate-900 px-8 py-8 overflow-y-auto"
  >
    <div class="flex-1 w-full">
      <div class="flex justify-between items-center mb-6">
        <h1 class="text-2xl font-semibold text-slate-800 dark:text-slate-100">
          Painel Administrativo
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
              Tabela de Preços
            </h2>
            <p class="text-sm text-slate-500 dark:text-slate-400 mt-1">
              Configure as regras de preço por marca, dia e categoria.
            </p>
          </div>
          <Button
            variant="solid"
            size="sm"
            class="flex items-center gap-2"
            @click="openAddModal"
          >
            <i class="i-lucide-plus" />
            Nova Regra
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
                <th class="px-6 py-4">Marca</th>
                <th class="px-6 py-4">Dias</th>
                <th class="px-6 py-4">Categoria</th>
                <th class="px-6 py-4">Duração</th>
                <th class="px-6 py-4">Preço</th>
                <th class="px-6 py-4 text-right">Ações</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-200 dark:divide-slate-700">
              <tr
                v-for="pricing in pricings"
                :key="pricing.id"
                class="hover:bg-slate-50 dark:hover:bg-slate-700/30 transition-colors"
              >
                <td
                  class="px-6 py-4 font-medium text-slate-900 dark:text-slate-100"
                >
                  {{ pricing.brandName || pricing.brand_id }}
                </td>
                <td class="px-6 py-4 text-slate-600 dark:text-slate-300">
                  {{ pricing.dayRange || pricing.day_range }}
                </td>
                <td class="px-6 py-4 text-slate-600 dark:text-slate-300">
                  {{ pricing.suiteCategory || pricing.suite_category }}
                </td>
                <td class="px-6 py-4 text-slate-600 dark:text-slate-300">
                  {{ pricing.duration }}
                </td>
                <td
                  class="px-6 py-4 font-medium text-slate-900 dark:text-slate-100"
                >
                  R$ {{ pricing.price }}
                </td>
                <td class="px-6 py-4 text-right flex justify-end gap-2">
                  <button
                    class="text-blue-600 hover:text-blue-800 font-medium"
                    @click="openEditModal(pricing)"
                  >
                    Editar
                  </button>
                  <button
                    class="text-red-600 hover:text-red-800 font-medium transition-colors"
                    @click="deletePricing(pricing)"
                  >
                    Excluir
                  </button>
                </td>
              </tr>
              <tr v-if="pricings.length === 0">
                <td colspan="6" class="px-6 py-8 text-center text-slate-500">
                  Nenhuma regra de preço cadastrada.
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <PricingModal
      :show="showModal"
      :pricing="selectedPricing"
      :brands="brands"
      @close="showModal = false"
      @save="handleSave"
    />
  </div>
</template>
