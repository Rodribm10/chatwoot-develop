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

const joinList = list => {
  if (!list) return '';
  return list.join(', ');
};

onMounted(fetchBrands);
</script>

<template>
  <div
    class="flex flex-col h-full w-full bg-slate-50 dark:bg-slate-900 px-8 py-8 overflow-y-auto"
  >
    <div class="flex-1 w-full">
      <div class="flex justify-between items-center mb-6">
        <h1 class="text-2xl font-semibold text-slate-800 dark:text-slate-100">
          {{ t('CAPTAIN.BRANDS.ADMIN_PANEL') }}
        </h1>
      </div>

      <div
        class="bg-white dark:bg-slate-800 rounded-lg shadow-sm border border-slate-200 dark:border-slate-700 w-full"
      >
        <div
          class="p-6 border-b border-slate-200 dark:border-slate-700 flex justify-between items-center bg-white dark:bg-slate-800 rounded-t-lg"
        >
          <h2 class="text-lg font-medium text-slate-800 dark:text-slate-100">
            {{ t('CAPTAIN.BRANDS.HEADER') }}
          </h2>
          <Button
            variant="smooth"
            size="sm"
            class="flex items-center gap-2"
            @click="openAddModal"
          >
            <i class="i-lucide-plus" />
            {{ t('CAPTAIN.BRANDS.ADD_NEW') }}
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
                <th class="px-6 py-4 w-1/4">
                  {{ t('CAPTAIN.BRANDS.TABLE.NAME') }}
                </th>
                <th class="px-6 py-4 w-1/3">
                  {{ t('CAPTAIN.BRANDS.TABLE.CATEGORIES') }}
                </th>
                <th class="px-6 py-4 w-1/4">
                  {{ t('CAPTAIN.BRANDS.TABLE.STAYS') }}
                </th>
                <th class="px-6 py-4 text-right">
                  {{ t('CAPTAIN.BRANDS.TABLE.ACTIONS') }}
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-200 dark:divide-slate-700">
              <tr
                v-for="brand in brands"
                :key="brand.id"
                class="hover:bg-slate-50 dark:hover:bg-slate-700/30 transition-colors"
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
                      class="break-words border-b border-slate-100 dark:border-slate-700/50 last:border-0 pb-1 last:pb-0"
                    >
                      <span class="font-medium">{{ cat }}</span>
                      <div
                        v-if="
                          (brand.suiteImages || brand.suite_images) &&
                          (brand.suiteImages || brand.suite_images)[cat]
                        "
                        class="text-xs text-blue-500 mt-0.5 truncate max-w-[300px]"
                        :title="(brand.suiteImages || brand.suite_images)[cat]"
                      >
                        <a
                          :href="(brand.suiteImages || brand.suite_images)[cat]"
                          target="_blank"
                          rel="noopener noreferrer"
                          class="hover:underline flex items-center gap-1"
                        >
                          <i class="i-lucide-link size-3" />
                          {{ t('CAPTAIN.BRANDS.VIEW_IMAGE') }}
                        </a>
                      </div>
                    </div>
                  </div>
                </td>
                <td
                  class="px-6 py-4 text-slate-600 dark:text-slate-300 align-top"
                >
                  {{ joinList(brand.stayDurations || brand.stay_durations) }}
                </td>
                <td class="px-6 py-4 text-right align-top">
                  <div class="flex justify-end gap-3">
                    <button
                      class="text-blue-600 hover:text-blue-800 font-medium text-sm"
                      @click="openEditModal(brand)"
                    >
                      {{ t('CAPTAIN.BRANDS.EDIT') }}
                    </button>
                    <button
                      class="text-red-500 hover:text-red-700 font-medium text-sm"
                      @click="deleteBrand(brand)"
                    >
                      {{ t('CAPTAIN.BRANDS.DELETE') }}
                    </button>
                  </div>
                </td>
              </tr>
              <tr v-if="brands.length === 0">
                <td
                  colspan="4"
                  class="px-6 py-12 text-center text-slate-500 border-t border-slate-200 dark:border-slate-700"
                >
                  <div class="flex flex-col items-center gap-2">
                    <i
                      class="i-lucide-building-2 text-4xl text-slate-300 mb-2"
                    />
                    <p
                      class="text-base font-medium text-slate-900 dark:text-slate-100"
                    >
                      {{ t('CAPTAIN.BRANDS.EMPTY_STATE_TITLE') }}
                    </p>
                    <p class="text-sm">
                      {{ t('CAPTAIN.BRANDS.EMPTY_STATE_DESC') }}
                    </p>
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
      :title="t('CAPTAIN.BRANDS.DELETE')"
      :description="t('CAPTAIN.BRANDS.DELETE_CONFIRMATION')"
      :confirm-button-label="t('CAPTAIN.BRANDS.DELETE')"
      @confirm="confirmDelete"
    />
  </div>
</template>
