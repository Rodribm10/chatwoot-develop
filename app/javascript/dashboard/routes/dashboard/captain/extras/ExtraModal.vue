<script setup>
import { ref, watch, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useRoute } from 'vue-router';
import WootModal from 'dashboard/components/Modal.vue';

const props = defineProps({
  show: Boolean,
  extra: {
    type: Object,
    default: null,
  },
});

const emit = defineEmits(['close', 'save']);

const { t } = useI18n();
const route = useRoute();
const accountId = route.params.accountId;

const formData = ref({
  title: '',
  description: '',
  price: '',
  category: '',
});

const isEditing = computed(() => !!props.extra);

watch(
  () => props.extra,
  newVal => {
    if (newVal) {
      formData.value = { ...newVal };
    } else {
      formData.value = { title: '', description: '', price: '', category: '' };
    }
  },
  { immediate: true }
);

const saveExtra = async () => {
  const payload = {
    extra: formData.value,
  };

  try {
    let response;
    if (isEditing.value) {
      response = await window.axios.put(
        `/api/v1/accounts/${accountId}/captain/extras/${props.extra.id}`,
        payload
      );
    } else {
      response = await window.axios.post(
        `/api/v1/accounts/${accountId}/captain/extras`,
        payload
      );
    }
    emit('save', response.data);
    emit('close');
    useAlert(t('CAPTAIN.EXTRAS.SUCCESS.SAVED'));
  } catch (error) {
    useAlert(t('CAPTAIN.EXTRAS.ERRORS.SAVE_FAILED'));
  }
};
</script>

<template>
  <!-- eslint-disable vue/no-bare-strings-in-template, @intlify/vue-i18n/no-raw-text -->
  <WootModal :show="show" :on-close="() => $emit('close')">
    <div class="flex flex-col h-auto overflow-visible">
      <div class="flex items-center justify-between px-6 py-4 border-b">
        <h3 class="text-base font-medium text-slate-800 dark:text-slate-100">
          {{ isEditing ? 'Editar Extra' : 'Novo Extra' }}
        </h3>
      </div>

      <div class="p-6 space-y-4">
        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">
            Nome do Item
          </label>
          <input
            v-model="formData.title"
            type="text"
            class="w-full px-3 py-2 border rounded-md dark:bg-slate-900 border-slate-200 dark:border-slate-700"
            placeholder="Ex: Café da Manhã"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">
            Descrição
          </label>
          <textarea
            v-model="formData.description"
            rows="3"
            class="w-full px-3 py-2 border rounded-md dark:bg-slate-900 border-slate-200 dark:border-slate-700"
            placeholder="Descrição do item extra"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">
            Preço (R$)
          </label>
          <input
            v-model="formData.price"
            type="number"
            step="0.01"
            class="w-full px-3 py-2 border rounded-md dark:bg-slate-900 border-slate-200 dark:border-slate-700"
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
          @click="saveExtra"
        >
          Salvar
        </button>
      </div>
    </div>
  </WootModal>
</template>
