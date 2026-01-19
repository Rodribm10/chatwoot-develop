<script setup>
import { ref, watch, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useRoute } from 'vue-router';
import WootModal from 'dashboard/components/Modal.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  show: Boolean,
  pricing: {
    type: Object,
    default: () => ({}),
  },
  brands: {
    type: Array,
    default: () => [],
  },
  inboxes: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['close', 'save']);
const { t } = useI18n();
const route = useRoute();
const accountId = route.params.accountId;

const formData = ref({
  captain_brand_id: '',
  inbox_ids: [],
  day_range: '',
  suite_category: '',
  duration: '',
  price: '',
});

const daysOptions = [
  'SEGUNDA',
  'TERÇA',
  'QUARTA',
  'QUINTA',
  'SEXTA',
  'SÁBADO',
  'DOMINGO',
];
const selectedDays = ref([]);
const selectedInboxes = ref([]);

const toggleDay = day => {
  if (selectedDays.value.includes(day)) {
    selectedDays.value = selectedDays.value.filter(d => d !== day);
  } else {
    // Sort logic to keep days in order
    const newSelection = [...selectedDays.value, day];
    selectedDays.value = newSelection.sort(
      (a, b) => daysOptions.indexOf(a) - daysOptions.indexOf(b)
    );
  }
  formData.value.day_range = selectedDays.value.join(', ');
};

const parseDays = rangeString => {
  if (!rangeString) return [];
  // Handle "SEGUNDA A QUARTA" range format legacy support
  if (rangeString.includes(' A ')) {
    const [start, end] = rangeString.split(' A ');
    const startIndex = daysOptions.indexOf(start);
    const endIndex = daysOptions.indexOf(end);
    if (startIndex !== -1 && endIndex !== -1 && startIndex <= endIndex) {
      return daysOptions.slice(startIndex, endIndex + 1);
    }
  }
  // Handle comma separated
  return rangeString
    .split(', ')
    .map(s => s.trim())
    .filter(s => daysOptions.includes(s));
};

const toggleInbox = inboxId => {
  if (selectedInboxes.value.includes(inboxId)) {
    selectedInboxes.value = selectedInboxes.value.filter(id => id !== inboxId);
  } else {
    selectedInboxes.value = [...selectedInboxes.value, inboxId];
  }
  formData.value.inbox_ids = selectedInboxes.value;
};

const removeInbox = inboxId => {
  selectedInboxes.value = selectedInboxes.value.filter(id => id !== inboxId);
  formData.value.inbox_ids = selectedInboxes.value;
};

const isEditing = computed(() => !!props.pricing?.id); // Changed to check for pricing.id to correctly identify editing mode

const selectedBrand = computed(() => {
  return props.brands.find(b => b.id === formData.value.captain_brand_id);
});

const brandCategories = computed(() => {
  if (!selectedBrand.value) return [];
  // Handle camelCase from API or snake_case
  return (
    selectedBrand.value.suiteCategories ||
    selectedBrand.value.suite_categories ||
    []
  );
});

const brandDurations = computed(() => {
  if (!selectedBrand.value) return [];
  return (
    selectedBrand.value.stayDurations ||
    selectedBrand.value.stay_durations ||
    []
  );
});

watch(
  () => props.pricing,
  newVal => {
    if (newVal && Object.keys(newVal).length > 0) {
      // Check if newVal is not empty object
      let normalizedInboxIds = [];
      if (newVal.inbox_ids?.length) {
        normalizedInboxIds = newVal.inbox_ids;
      } else if (newVal.inbox_id) {
        normalizedInboxIds = [newVal.inbox_id];
      }
      formData.value = { ...newVal, inbox_ids: normalizedInboxIds };
      selectedDays.value = parseDays(newVal.day_range || newVal.dayRange);
      selectedInboxes.value = normalizedInboxIds;
    } else {
      formData.value = {
        captain_brand_id: props.brands.length > 0 ? props.brands[0].id : '',
        inbox_ids: props.inboxes.length > 0 ? [props.inboxes[0].id] : [],
        day_range: '',
        suite_category: '',
        duration: '',
        price: '',
      };
      selectedDays.value = [];
      selectedInboxes.value = formData.value.inbox_ids;
    }
  },
  { immediate: true }
);

const savePricing = async () => {
  const payload = {
    pricing: formData.value,
  };

  try {
    let response;
    if (isEditing.value) {
      response = await window.axios.put(
        `/api/v1/accounts/${accountId}/captain/pricings/${props.pricing.id}`,
        payload
      );
    } else {
      response = await window.axios.post(
        `/api/v1/accounts/${accountId}/captain/pricings`,
        payload
      );
    }
    emit('save', response.data);
    emit('close');
    useAlert(t('CAPTAIN.PRICINGS.MODAL.SAVE_SUCCESS'));
  } catch (error) {
    useAlert(t('CAPTAIN.PRICINGS.MODAL.SAVE_ERROR'));
  }
};
</script>

<template>
  <WootModal :show="show" :on-close="() => emit('close')">
    <div class="flex flex-col h-auto overflow-visible">
      <div class="flex items-center justify-between px-6 py-4 border-b">
        <h3 class="text-base font-medium text-slate-800 dark:text-slate-100">
          {{
            isEditing
              ? $t('CAPTAIN.PRICINGS.MODAL.EDIT_TITLE')
              : $t('CAPTAIN.PRICINGS.MODAL.ADD_TITLE')
          }}
        </h3>
      </div>

      <div class="p-6 space-y-4">
        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">
            {{ $t('CAPTAIN.PRICINGS.FIELDS.INBOX') }}
          </label>
          <div class="flex flex-wrap gap-2">
            <button
              v-for="inbox in inboxes"
              :key="inbox.id"
              type="button"
              class="px-3 py-1.5 text-xs font-medium rounded-full border transition-colors"
              :class="[
                selectedInboxes.includes(inbox.id)
                  ? 'bg-blue-600 text-white border-blue-600'
                  : 'bg-white text-slate-600 border-slate-200 hover:border-slate-300 dark:bg-slate-800 dark:text-slate-300 dark:border-slate-700',
              ]"
              @click="toggleInbox(inbox.id)"
            >
              {{ inbox.name }}
            </button>
          </div>
          <div v-if="selectedInboxes.length" class="flex flex-wrap gap-2 mt-2">
            <span
              v-for="inboxId in selectedInboxes"
              :key="inboxId"
              class="inline-flex items-center gap-1 px-2 py-1 text-xs rounded-full bg-slate-100 text-slate-700 border border-slate-200"
            >
              {{
                inboxes.find(i => i.id === inboxId)?.name || `Inbox ${inboxId}`
              }}
              <button
                type="button"
                :aria-label="$t('CAPTAIN.PRICINGS.MODAL.REMOVE_INBOX')"
                class="text-slate-500 hover:text-slate-700"
                @click="removeInbox(inboxId)"
              >
                {{ $t('CAPTAIN.PRICINGS.MODAL.CLOSE') }}
              </button>
            </span>
          </div>
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">
            {{ $t('CAPTAIN.PRICINGS.FIELDS.BRAND') }}
          </label>
          <select
            v-model="formData.captain_brand_id"
            class="w-full px-3 py-2 border rounded-md dark:bg-slate-900 border-slate-200 dark:border-slate-700"
          >
            <option v-for="brand in brands" :key="brand.id" :value="brand.id">
              {{ brand.name }}
            </option>
          </select>
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-2">
            {{ $t('CAPTAIN.PRICINGS.MODAL.FIELDS.DAYS_WEEK') }}
          </label>
          <div class="flex flex-wrap gap-2">
            <button
              v-for="day in daysOptions"
              :key="day"
              type="button"
              class="px-3 py-1.5 text-xs font-medium rounded-full border transition-colors"
              :class="[
                selectedDays.includes(day)
                  ? 'bg-indigo-600 text-white border-indigo-600 shadow-sm'
                  : 'bg-white text-slate-600 border-slate-300 hover:border-slate-400 dark:bg-slate-800 dark:text-slate-300 dark:border-slate-700',
              ]"
              @click="toggleDay(day)"
            >
              {{ day }}
            </button>
          </div>
          <p
            v-if="selectedDays.length === 0"
            class="text-xs text-orange-500 mt-1"
          >
            {{ $t('CAPTAIN.PRICINGS.MODAL.SELECT_DAYS_REQUIRED') }}
          </p>
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">
            {{ $t('CAPTAIN.PRICINGS.FIELDS.CATEGORY') }}
          </label>
          <select
            v-model="formData.suite_category"
            class="w-full px-3 py-2 border rounded-md dark:bg-slate-900 border-slate-200 dark:border-slate-700"
            :disabled="!brandCategories.length"
          >
            <option value="" disabled>
              {{ $t('CAPTAIN.PRICINGS.MODAL.SELECT_CATEGORY') }}
            </option>
            <option v-for="cat in brandCategories" :key="cat" :value="cat">
              {{ cat }}
            </option>
          </select>
          <p
            v-if="!formData.captain_brand_id"
            class="text-xs text-slate-500 mt-1"
          >
            {{ $t('CAPTAIN.PRICINGS.MODAL.SELECT_BRAND_FIRST') }}
          </p>
          <p
            v-else-if="!brandCategories.length"
            class="text-xs text-orange-500 mt-1"
          >
            {{ $t('CAPTAIN.PRICINGS.MODAL.NO_CATEGORIES') }}
          </p>
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">
            {{ $t('CAPTAIN.PRICINGS.FIELDS.DURATION') }}
          </label>
          <select
            v-model="formData.duration"
            class="w-full px-3 py-2 border rounded-md dark:bg-slate-900 border-slate-200 dark:border-slate-700"
            :disabled="!brandDurations.length"
          >
            <option value="" disabled>
              {{ $t('CAPTAIN.PRICINGS.MODAL.SELECT_DURATION') }}
            </option>
            <option v-for="dur in brandDurations" :key="dur" :value="dur">
              {{ dur }}
            </option>
          </select>
          <p
            v-if="!formData.captain_brand_id"
            class="text-xs text-slate-500 mt-1"
          >
            {{ $t('CAPTAIN.PRICINGS.MODAL.SELECT_BRAND_FIRST') }}
          </p>
          <p
            v-else-if="!brandDurations.length"
            class="text-xs text-orange-500 mt-1"
          >
            {{ $t('CAPTAIN.PRICINGS.MODAL.NO_DURATIONS') }}
          </p>
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">
            {{ $t('CAPTAIN.PRICINGS.FIELDS.PRICE') }}
          </label>
          <input
            v-model="formData.price"
            type="number"
            step="0.01"
            class="w-full px-3 py-2 border rounded-md dark:bg-slate-900 border-slate-200 dark:border-slate-700"
            :placeholder="$t('CAPTAIN.PRICINGS.MODAL.PRICE_PLACEHOLDER')"
          />
        </div>
      </div>

      <div
        class="flex items-center justify-end px-6 py-4 border-t bg-slate-50 dark:bg-slate-800 rounded-b-md gap-2"
      >
        <button
          class="text-slate-600 hover:text-slate-800 px-4 py-2"
          @click="emit('close')"
        >
          {{ $t('CAPTAIN.PRICINGS.MODAL.CANCEL') }}
        </button>
        <Button
          :label="$t('CAPTAIN.PRICINGS.MODAL.SAVE')"
          @click="savePricing"
        />
      </div>
    </div>
  </WootModal>
</template>
