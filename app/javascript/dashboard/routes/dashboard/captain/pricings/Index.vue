<script setup>
import { onMounted, ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useRoute } from 'vue-router';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import PricingModal from './PricingModal.vue';

const { t } = useI18n();
const pricings = ref([]);
const brands = ref([]);
const inboxes = ref([]);
const isLoading = ref(false);
const showModal = ref(false);
const showDeleteConfirmation = ref(false);
const pricingToDelete = ref(null);
const selectedPricing = ref(null);
const route = useRoute();
const accountId = route.params.accountId;
const selectedBrandId = ref('');
const selectedDay = ref('');
const selectedCategory = ref('');
const selectedDuration = ref('');
const minPrice = ref('');
const maxPrice = ref('');

const daysOptions = [
  'SEGUNDA',
  'TERÇA',
  'QUARTA',
  'QUINTA',
  'SEXTA',
  'SÁBADO',
  'DOMINGO',
];

const availableCategories = computed(() => {
  const categories = pricings.value
    .map(p => p.suiteCategory || p.suite_category)
    .filter(Boolean);
  return [...new Set(categories)].sort();
});

const availableDurations = computed(() => {
  const durations = pricings.value.map(p => p.duration).filter(Boolean);
  return [...new Set(durations)].sort();
});

const filteredPricings = computed(() => {
  const min = minPrice.value ? Number(minPrice.value) : null;
  const max = maxPrice.value ? Number(maxPrice.value) : null;

  return pricings.value.filter(pricing => {
    const brandId = pricing.brand_id || pricing.brandId;
    const dayRange = pricing.day_range || pricing.dayRange || '';
    const category = pricing.suite_category || pricing.suiteCategory || '';
    const duration = pricing.duration || '';
    const price = Number(pricing.price || 0);

    if (
      selectedBrandId.value &&
      Number(selectedBrandId.value) !== Number(brandId)
    ) {
      return false;
    }
    if (selectedDay.value && !dayRange.includes(selectedDay.value)) {
      return false;
    }
    if (selectedCategory.value && selectedCategory.value !== category) {
      return false;
    }
    if (selectedDuration.value && selectedDuration.value !== duration) {
      return false;
    }
    if (min !== null && price < min) {
      return false;
    }
    if (max !== null && price > max) {
      return false;
    }
    return true;
  });
});

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
    const [pricesRes, brandsRes, inboxesRes] = await Promise.all([
      window.axios.get(`/api/v1/accounts/${accountId}/captain/pricings`),
      window.axios.get(`/api/v1/accounts/${accountId}/captain/brands`),
      window.axios.get(`/api/v1/accounts/${accountId}/inboxes`),
    ]);
    pricings.value = pricesRes.data;
    brands.value = brandsRes.data;
    inboxes.value = inboxesRes.data.payload || [];
  } catch (error) {
    useAlert(t('CAPTAIN.PRICINGS.FETCH_ERROR'));
  } finally {
    isLoading.value = false;
  }
};

const confirmDelete = pricing => {
  pricingToDelete.value = pricing;
  showDeleteConfirmation.value = true;
};

const deletePricing = async () => {
  if (!pricingToDelete.value) return;
  try {
    await window.axios.delete(
      `/api/v1/accounts/${accountId}/captain/pricings/${pricingToDelete.value.id}`
    );
    pricings.value = pricings.value.filter(
      p => p.id !== pricingToDelete.value.id
    );
    useAlert(t('CAPTAIN.PRICINGS.DELETE_SUCCESS'));
  } catch (error) {
    useAlert(t('CAPTAIN.PRICINGS.DELETE_ERROR'));
  } finally {
    showDeleteConfirmation.value = false;
    pricingToDelete.value = null;
  }
};

onMounted(fetchData);

const clearFilters = () => {
  selectedBrandId.value = '';
  selectedDay.value = '';
  selectedCategory.value = '';
  selectedDuration.value = '';
  minPrice.value = '';
  maxPrice.value = '';
};
</script>

<template>
  <div
    class="flex flex-col h-full w-full bg-slate-50 dark:bg-slate-900 px-8 py-8 overflow-y-auto"
  >
    <div class="flex-1 w-full">
      <div class="flex justify-between items-center mb-6">
        <h1 class="text-2xl font-semibold text-slate-800 dark:text-slate-100">
          {{ $t('CAPTAIN.PRICINGS.HEADER') }}
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
              {{ $t('CAPTAIN.PRICINGS.TITLE') }}
            </h2>
            <p class="text-sm text-slate-500 dark:text-slate-400 mt-1">
              {{ $t('CAPTAIN.PRICINGS.DESCRIPTION') }}
            </p>
          </div>
          <Button
            variant="solid"
            size="sm"
            class="flex items-center gap-2"
            @click="openAddModal"
          >
            <i class="i-lucide-plus" />
            {{ $t('CAPTAIN.PRICINGS.ADD_BUTTON') }}
          </Button>
        </div>

        <div class="p-6 border-b border-slate-200 dark:border-slate-700">
          <div class="grid grid-cols-1 md:grid-cols-3 xl:grid-cols-6 gap-3">
            <div>
              <label class="block text-xs font-medium text-slate-500 mb-1">
                {{ $t('CAPTAIN.PRICINGS.FIELDS.BRAND') }}
              </label>
              <select
                v-model="selectedBrandId"
                class="w-full px-3 py-2 border rounded-md dark:bg-slate-900 border-slate-200 dark:border-slate-700"
              >
                <option value="">
                  {{ $t('CAPTAIN.PRICINGS.FILTERS.ALL') }}
                </option>
                <option
                  v-for="brand in brands"
                  :key="brand.id"
                  :value="brand.id"
                >
                  {{ brand.name }}
                </option>
              </select>
            </div>
            <div>
              <label class="block text-xs font-medium text-slate-500 mb-1">
                {{ $t('CAPTAIN.PRICINGS.FIELDS.DAY') }}
              </label>
              <select
                v-model="selectedDay"
                class="w-full px-3 py-2 border rounded-md dark:bg-slate-900 border-slate-200 dark:border-slate-700"
              >
                <option value="">
                  {{ $t('CAPTAIN.PRICINGS.FILTERS.ALL_DAYS') }}
                </option>
                <option v-for="day in daysOptions" :key="day" :value="day">
                  {{ day }}
                </option>
              </select>
            </div>
            <div>
              <label class="block text-xs font-medium text-slate-500 mb-1">
                {{ $t('CAPTAIN.PRICINGS.FIELDS.CATEGORY') }}
              </label>
              <select
                v-model="selectedCategory"
                class="w-full px-3 py-2 border rounded-md dark:bg-slate-900 border-slate-200 dark:border-slate-700"
              >
                <option value="">
                  {{ $t('CAPTAIN.PRICINGS.FILTERS.ALL') }}
                </option>
                <option
                  v-for="category in availableCategories"
                  :key="category"
                  :value="category"
                >
                  {{ category }}
                </option>
              </select>
            </div>
            <div>
              <label class="block text-xs font-medium text-slate-500 mb-1">
                {{ $t('CAPTAIN.PRICINGS.FIELDS.DURATION') }}
              </label>
              <select
                v-model="selectedDuration"
                class="w-full px-3 py-2 border rounded-md dark:bg-slate-900 border-slate-200 dark:border-slate-700"
              >
                <option value="">
                  {{ $t('CAPTAIN.PRICINGS.FILTERS.ALL') }}
                </option>
                <option
                  v-for="duration in availableDurations"
                  :key="duration"
                  :value="duration"
                >
                  {{ duration }}
                </option>
              </select>
            </div>
            <Input
              v-model="minPrice"
              :label="$t('CAPTAIN.PRICINGS.FIELDS.MIN_PRICE')"
              type="number"
              class="w-full"
            />
            <Input
              v-model="maxPrice"
              :label="$t('CAPTAIN.PRICINGS.FIELDS.MAX_PRICE')"
              type="number"
              class="w-full"
            />
          </div>
          <div class="flex justify-end mt-4">
            <Button
              size="sm"
              ghost
              :label="$t('CAPTAIN.PRICINGS.FILTERS.CLEAR')"
              @click="clearFilters"
            />
          </div>
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
                <th class="px-6 py-4">
                  {{ $t('CAPTAIN.PRICINGS.FIELDS.INBOX') }}
                </th>
                <th class="px-6 py-4">
                  {{ $t('CAPTAIN.PRICINGS.FIELDS.BRAND') }}
                </th>
                <th class="px-6 py-4">
                  {{ $t('CAPTAIN.PRICINGS.FIELDS.DAYS') }}
                </th>
                <th class="px-6 py-4">
                  {{ $t('CAPTAIN.PRICINGS.FIELDS.CATEGORY') }}
                </th>
                <th class="px-6 py-4">
                  {{ $t('CAPTAIN.PRICINGS.FIELDS.DURATION') }}
                </th>
                <th class="px-6 py-4">
                  {{ $t('CAPTAIN.PRICINGS.FIELDS.PRICE') }}
                </th>
                <th class="px-6 py-4 text-right">
                  {{ $t('CAPTAIN.PRICINGS.FIELDS.ACTIONS') }}
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-200 dark:divide-slate-700">
              <tr
                v-for="pricing in filteredPricings"
                :key="pricing.id"
                class="hover:bg-slate-50 dark:hover:bg-slate-700/30 transition-colors"
              >
                <td
                  class="px-6 py-4 font-medium text-slate-900 dark:text-slate-100"
                >
                  {{
                    pricing.inboxNames?.length
                      ? pricing.inboxNames.join(', ')
                      : pricing.inbox_names?.length
                        ? pricing.inbox_names.join(', ')
                        : pricing.inboxName ||
                          pricing.inbox_name ||
                          pricing.inbox_id
                  }}
                </td>
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
                  {{
                    $t('CAPTAIN.PRICINGS.FIELDS.PRICE_DISPLAY', {
                      price: pricing.price,
                    })
                  }}
                </td>
                <td class="px-6 py-4 text-right flex justify-end gap-2">
                  <button
                    class="text-blue-600 hover:text-blue-800 font-medium"
                    @click="openEditModal(pricing)"
                  >
                    {{ $t('CAPTAIN.RESERVATIONS.AUTOMATIONS.EDIT') }}
                  </button>
                  <button
                    class="text-red-600 hover:text-red-800 font-medium transition-colors"
                    @click="confirmDelete(pricing)"
                  >
                    {{ $t('CAPTAIN.RESERVATIONS.AUTOMATIONS.DELETE') }}
                  </button>
                </td>
              </tr>
              <tr v-if="filteredPricings.length === 0">
                <td colspan="7" class="px-6 py-8 text-center text-slate-500">
                  {{ $t('CAPTAIN.PRICINGS.EMPTY_STATE') }}
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
      :inboxes="inboxes"
      @close="showModal = false"
      @save="handleSave"
    />

    <Dialog
      :show="showDeleteConfirmation"
      :title="t('CAPTAIN.PRICINGS.DELETE_BUTTON')"
      :message="t('CAPTAIN.PRICINGS.DELETE_CONFIRMATION')"
      :confirm-text="t('CAPTAIN.PRICINGS.DELETE_BUTTON')"
      :cancel-text="t('CAPTAIN.BRAND_MODAL.CANCEL')"
      variant="danger"
      @close="showDeleteConfirmation = false"
      @confirm="deletePricing"
    />
  </div>
</template>
