<script setup>
import { ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useRoute } from 'vue-router';
import BrandModal from './BrandModal.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const { t } = useI18n();
const route = useRoute();
const accountId = route.params.accountId;

const brands = ref([]);
const isLoading = ref(false);
const showModal = ref(false);
const selectedBrand = ref(null);
const deleteDialogRef = ref(null);
const brandToDelete = ref(null);

const fetchBrands = async () => {
  isLoading.value = true;
  try {
    const response = await window.axios.get(
      `/api/v1/accounts/${accountId}/captain/brands`
    );
    brands.value = response.data;
  } catch (error) {
    useAlert(t('CAPTAIN.BRANDS.ERRORS.FETCH_FAILED'));
  } finally {
    isLoading.value = false;
  }
};

const openAddModal = () => {
  selectedBrand.value = null;
  showModal.value = true;
};

const openEditModal = brand => {
  selectedBrand.value = brand;
  showModal.value = true;
};

const deleteBrand = brand => {
  brandToDelete.value = brand;
  deleteDialogRef.value.show();
};

const confirmDelete = async () => {
  if (!brandToDelete.value) return;

  try {
    await window.axios.delete(
      `/api/v1/accounts/${accountId}/captain/brands/${brandToDelete.value.id}`
    );
    brands.value = brands.value.filter(b => b.id !== brandToDelete.value.id);
    useAlert(t('CAPTAIN.BRANDS.SUCCESS.DELETED'));
  } catch (error) {
    useAlert(t('CAPTAIN.BRANDS.ERRORS.DELETE_FAILED'));
  } finally {
    brandToDelete.value = null;
  }
};

const handleSave = async brandData => {
  try {
    let response;
    if (selectedBrand.value) {
      // Update existing brand
      response = await window.axios.put(
        `/api/v1/accounts/${accountId}/captain/brands/${selectedBrand.value.id}`,
        { brand: brandData }
      );
      const index = brands.value.findIndex(
        b => b.id === selectedBrand.value.id
      );
      if (index !== -1) {
        brands.value[index] = response.data;
      }
      useAlert(t('CAPTAIN.BRANDS.SUCCESS.UPDATED'));
    } else {
      // Create new brand
      response = await window.axios.post(
        `/api/v1/accounts/${accountId}/captain/brands`,
        { brand: brandData }
      );
      brands.value.push(response.data);
      useAlert(t('CAPTAIN.BRANDS.SUCCESS.CREATED'));
    }
    showModal.value = false;
  } catch (error) {
    useAlert(t('CAPTAIN.BRANDS.ERRORS.SAVE_FAILED'));
  }
};

onMounted(() => {
  fetchBrands();
});
</script>

<template>
  <!-- eslint-disable vue/no-bare-strings-in-template, @intlify/vue-i18n/no-raw-text -->
  <div
    class="flex flex-col h-full w-full bg-slate-50 dark:bg-slate-900 px-8 py-8 overflow-y-auto"
  >
    <div class="flex-1 w-full max-w-7xl mx-auto">
      <div class="flex justify-between items-center mb-6">
        <div>
          <h1 class="text-2xl font-semibold text-slate-800 dark:text-slate-100">
            Painel Admin de Marcas
          </h1>
          <p class="text-slate-500 dark:text-slate-400 mt-1">
            Gerenciamento de Marcas
          </p>
        </div>
        <Button
          variant="solid"
          size="sm"
          class="flex items-center gap-2 shadow-sm"
          @click="openAddModal"
        >
          <i class="i-lucide-plus" />
          Adicionar Nova Marca
        </Button>
      </div>

      <div
        class="bg-white dark:bg-slate-800 rounded-lg shadow-sm border border-slate-200 dark:border-slate-700 w-full overflow-hidden"
      >
        <div v-if="isLoading" class="p-12 flex justify-center">
          <Spinner />
        </div>

        <div v-else class="overflow-x-auto">
          <table class="w-full text-left text-sm">
            <thead
              class="bg-slate-50 dark:bg-slate-700/50 text-slate-500 dark:text-slate-300 uppercase font-medium border-b border-slate-200 dark:border-slate-700"
            >
              <tr>
                <th class="px-6 py-4 w-1/4">Nome da Marca</th>
                <th class="px-6 py-4 w-1/3">Categorias de Suíte</th>
                <th class="px-6 py-4 w-1/4">Durações de Estadia</th>
                <th class="px-6 py-4 text-right">Ações</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-200 dark:divide-slate-700">
              <tr
                v-for="brand in brands"
                :key="brand.id"
                class="hover:bg-slate-50 dark:hover:bg-slate-700/30 transition-colors group"
              >
                <td
                  class="px-6 py-4 font-medium text-slate-900 dark:text-slate-100 align-top"
                >
                  {{ brand.name }}
                </td>
                <td
                  class="px-6 py-4 text-slate-600 dark:text-slate-300 align-top"
                >
                  <div class="flex flex-col gap-2">
                    <div
                      v-for="(cat, idx) in brand.suiteCategories ||
                      brand.suite_categories ||
                      []"
                      :key="idx"
                      class="flex items-start gap-2 group/cat"
                    >
                      <span
                        class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-slate-100 dark:bg-slate-700 text-slate-700 dark:text-slate-300"
                      >
                        {{ cat }}
                      </span>
                      <a
                        v-if="
                          (brand.suiteImages || brand.suite_images) &&
                          (brand.suiteImages || brand.suite_images)[cat]
                        "
                        :href="(brand.suiteImages || brand.suite_images)[cat]"
                        target="_blank"
                        rel="noopener noreferrer"
                        class="text-blue-500 hover:text-blue-700 transition-colors opacity-0 group-hover/cat:opacity-100"
                        :title="t('CAPTAIN.BRANDS.VIEW_IMAGE')"
                      >
                        <i class="i-lucide-image size-3.5" />
                      </a>
                    </div>
                  </div>
                </td>
                <td
                  class="px-6 py-4 text-slate-600 dark:text-slate-300 align-top"
                >
                  <div class="flex flex-wrap gap-1.5">
                    <span
                      v-for="(stay, sIdx) in brand.stayDurations ||
                      brand.stay_durations ||
                      []"
                      :key="sIdx"
                      class="inline-flex text-xs text-slate-600 dark:text-slate-300 bg-slate-100 dark:bg-slate-700 px-2 py-0.5 rounded border border-slate-200 dark:border-slate-600"
                    >
                      {{ stay }}
                    </span>
                  </div>
                </td>
                <td class="px-6 py-4 text-right align-top">
                  <div class="flex justify-end gap-2">
                    <button
                      class="text-blue-600 hover:text-blue-800 font-medium transition-colors"
                      @click="openEditModal(brand)"
                    >
                      Editar
                    </button>
                    <button
                      class="text-red-500 hover:text-red-700 font-medium transition-colors"
                      @click="deleteBrand(brand)"
                    >
                      Excluir
                    </button>
                  </div>
                </td>
              </tr>
              <tr v-if="brands.length === 0">
                <td colspan="4" class="px-6 py-24 text-center text-slate-500">
                  <div
                    class="flex flex-col items-center justify-center gap-3 animate-fade-in"
                  >
                    <div
                      class="p-4 bg-slate-100 dark:bg-slate-700/50 rounded-full mb-2"
                    >
                      <i
                        class="i-lucide-hotel text-3xl text-slate-400 dark:text-slate-500"
                      />
                    </div>
                    <h3
                      class="text-lg font-semibold text-slate-800 dark:text-slate-100"
                    >
                      Nenhuma marca encontrada
                    </h3>
                    <p
                      class="text-sm text-slate-500 dark:text-slate-400 max-w-sm mx-auto"
                    >
                      Adicione sua primeira marca para começar a configurar
                      preços e quartos.
                    </p>
                    <Button
                      variant="solid"
                      size="sm"
                      class="mt-4"
                      @click="openAddModal"
                    >
                      Adicionar Nova Marca
                    </Button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <BrandModal
      :show="showModal"
      :brand="selectedBrand"
      @close="showModal = false"
      @save="handleSave"
    />

    <Dialog
      ref="deleteDialogRef"
      type="alert"
      title="Excluir Marca"
      description="Tem certeza que deseja excluir esta marca? Essa ação não pode ser desfeita."
      confirm-button-label="Excluir"
      @confirm="confirmDelete"
    />
  </div>
</template>
