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
  <WootModal :show="show" :on-close="() => $emit('close')">
    <div class="flex flex-col h-auto overflow-visible">
      <div class="flex items-center justify-between px-6 py-4 border-b">
        <h3 class="text-base font-medium text-slate-800 dark:text-slate-100">
          {{
            isEditing
              ? t('CAPTAIN.EXTRAS.MODAL.TITLE_EDIT')
              : t('CAPTAIN.EXTRAS.MODAL.TITLE_NEW')
          }}
        </h3>
        <button
          class="text-slate-500 hover:text-slate-800"
          @click="emit('close')"
        >
          <span class="sr-only">{{ t('CAPTAIN.EXTRAS.MODAL.CANCEL') }}</span>
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
          <label class="block text-sm font-medium text-slate-700 mb-1">
            {{ t('CAPTAIN.EXTRAS.MODAL.TITLE_LABEL') }}
          </label>
          <input
            v-model="formData.title"
            type="text"
            class="w-full px-3 py-2 border rounded-md dark:bg-slate-900 border-slate-200 dark:border-slate-700"
            :placeholder="t('CAPTAIN.EXTRAS.MODAL.TITLE_PLACEHOLDER')"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">
            {{ t('CAPTAIN.EXTRAS.MODAL.DESCRIPTION_LABEL') }}
          </label>
          <textarea
            v-model="formData.description"
            rows="3"
            class="w-full px-3 py-2 border rounded-md dark:bg-slate-900 border-slate-200 dark:border-slate-700"
            :placeholder="t('CAPTAIN.EXTRAS.MODAL.DESCRIPTION_PLACEHOLDER')"
          />
        </div>

        <div>
          <label class="block text-sm font-medium text-slate-700 mb-1">
            {{ t('CAPTAIN.EXTRAS.MODAL.PRICE_LABEL') }}
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
          {{ t('CAPTAIN.EXTRAS.MODAL.CANCEL') }}
        </button>
        <button
          class="bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-700"
          @click="saveExtra"
        >
          {{ t('CAPTAIN.EXTRAS.MODAL.SUBMIT') }}
        </button>
      </div>
    </div>
  </WootModal>
</template>
