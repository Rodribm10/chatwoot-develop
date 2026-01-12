<script setup>
import { ref, watch, computed } from 'vue';
import { useAlert } from 'dashboard/composables';
import { useRoute } from 'vue-router';
import WootModal from 'dashboard/components/Modal.vue';

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
});

const emit = defineEmits(['close', 'save']);
const route = useRoute();
const accountId = route.params.accountId;

const formData = ref({
  captain_brand_id: '',
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

const isEditing = computed(() => !!props.pricing.id); // Changed to check for pricing.id to correctly identify editing mode

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
      formData.value = { ...newVal };
      selectedDays.value = parseDays(newVal.day_range || newVal.dayRange);
    } else {
      formData.value = {
        captain_brand_id: props.brands.length > 0 ? props.brands[0].id : '',
        day_range: '',
        suite_category: '',
        duration: '',
        price: '',
      };
      selectedDays.value = [];
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
    useAlert('Preço salvo!');
  } catch (error) {
    useAlert('Erro ao salvar preço');
  }
};
</script>

<template>
  <!-- eslint-disable vue/no-bare-strings-in-template -->
  <WootModal :show="show" :on-close="() => emit('close')">
    <div class="flex flex-col h-auto overflow-visible">
      <div class="flex items-center justify-between px-6 py-4 border-b">
        <h3 class="text-base font-medium text-slate-800 dark:text-slate-100">
          {{ isEditing ? 'Editar Regra' : 'Nova Regra de Preço' }}
        </h3>
        <button
          class="text-slate-500 hover:text-slate-800"
          @click="emit('close')"
        >
          <span class="sr-only">Close</span>
          <svg
            class="w-6 h-6"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M6 18L18 6M6 6l12 12"
            />
          </svg>
        </button>
      </div>

      <div class="p-6 space-y-4">
        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1"
            >Marca</label
          >
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
          <label class="block text-sm font-medium text-slate-700 mb-2"
            >Dias da Semana</label
          >
          <div class="flex flex-wrap gap-2">
            <button
              v-for="day in daysOptions"
              :key="day"
              type="button"
              class="px-3 py-1.5 text-xs font-medium rounded-full border transition-colors"
              :class="[
                selectedDays.includes(day)
                  ? 'bg-blue-600 text-white border-blue-600'
                  : 'bg-white text-slate-600 border-slate-200 hover:border-slate-300 dark:bg-slate-800 dark:text-slate-300 dark:border-slate-700',
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
            Selecione pelo menos um dia.
          </p>
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1"
            >Categoria de Suíte</label
          >
          <select
            v-model="formData.suite_category"
            class="w-full px-3 py-2 border rounded-md dark:bg-slate-900 border-slate-200 dark:border-slate-700"
            :disabled="!brandCategories.length"
          >
            <option value="" disabled>Selecione uma categoria</option>
            <option v-for="cat in brandCategories" :key="cat" :value="cat">
              {{ cat }}
            </option>
          </select>
          <p
            v-if="!formData.captain_brand_id"
            class="text-xs text-slate-500 mt-1"
          >
            Selecione uma marca primeiro.
          </p>
          <p
            v-else-if="!brandCategories.length"
            class="text-xs text-orange-500 mt-1"
          >
            Nenhuma categoria cadastrada nesta marca.
          </p>
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1"
            >Duração</label
          >
          <select
            v-model="formData.duration"
            class="w-full px-3 py-2 border rounded-md dark:bg-slate-900 border-slate-200 dark:border-slate-700"
            :disabled="!brandDurations.length"
          >
            <option value="" disabled>Selecione uma duração</option>
            <option v-for="dur in brandDurations" :key="dur" :value="dur">
              {{ dur }}
            </option>
          </select>
          <p
            v-if="!formData.captain_brand_id"
            class="text-xs text-slate-500 mt-1"
          >
            Selecione uma marca primeiro.
          </p>
          <p
            v-else-if="!brandDurations.length"
            class="text-xs text-orange-500 mt-1"
          >
            Nenhuma duração cadastrada nesta marca.
          </p>
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1"
            >Preço (R$)</label
          >
          <input
            v-model="formData.price"
            type="number"
            step="0.01"
            class="w-full px-3 py-2 border rounded-md dark:bg-slate-900 border-slate-200 dark:border-slate-700"
            placeholder="0.00"
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
          Cancelar
        </button>
        <button
          class="bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-700"
          @click="savePricing"
        >
          Salvar
        </button>
      </div>
    </div>
  </WootModal>
</template>
