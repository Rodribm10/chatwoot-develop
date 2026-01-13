<script setup>
/* eslint-disable @intlify/vue-i18n/no-dynamic-keys */
import { ref, computed } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import AssistantForm from './AssistantForm.vue';

const props = defineProps({
  selectedAssistant: {
    type: Object,
    default: () => ({}),
  },
  type: {
    type: String,
    default: 'create',
    validator: value => ['create', 'edit'].includes(value),
  },
});
const emit = defineEmits(['close', 'created']);
const { t } = useI18n();
const store = useStore();

const dialogRef = ref(null);
const assistantForm = ref(null);

const updateAssistant = assistantDetails =>
  store.dispatch('captainAssistants/update', {
    id: props.selectedAssistant.id,
    ...assistantDetails,
  });

const i18nKey = computed(
  () => `CAPTAIN.ASSISTANTS.${props.type.toUpperCase()}`
);

/* eslint-disable @intlify/vue-i18n/no-dynamic-keys */
const createAssistant = async assistantDetails => {
  try {
    const newAssistant = await store.dispatch(
      'captainAssistants/create',
      assistantDetails
    );
    emit('created', newAssistant);
  } catch (error) {
    // eslint-disable-next-line @intlify/vue-i18n/no-dynamic-keys
    const errorMessage = error?.message || t(`${i18nKey.value}.ERROR_MESSAGE`);
    useAlert(errorMessage);
  }
};

const handleSubmit = async updatedAssistant => {
  try {
    if (props.type === 'edit') {
      await updateAssistant(updatedAssistant);
    } else {
      await createAssistant(updatedAssistant);
    }
    // eslint-disable-next-line @intlify/vue-i18n/no-dynamic-keys
    useAlert(t(`${i18nKey.value}.SUCCESS_MESSAGE`));
    dialogRef.value.close();
  } catch (error) {
    // eslint-disable-next-line @intlify/vue-i18n/no-dynamic-keys
    const errorMessage = error?.message || t(`${i18nKey.value}.ERROR_MESSAGE`);
    useAlert(errorMessage);
  }
};
/* eslint-enable @intlify/vue-i18n/no-dynamic-keys */

const handleClose = () => {
  emit('close');
};

const handleCancel = () => {
  dialogRef.value.close();
};

defineExpose({ dialogRef });
</script>

<template>
  <!-- eslint-disable vue/no-bare-strings-in-template -->
  <!-- eslint-disable @intlify/vue-i18n/no-dynamic-keys -->
  <Dialog
    ref="dialogRef"
    :type="type"
    :title="t(`${i18nKey}.TITLE`)"
    :description="t('CAPTAIN.ASSISTANTS.FORM_DESCRIPTION')"
    :show-cancel-button="false"
    :show-confirm-button="false"
    overflow-y-auto
    @close="handleClose"
  >
    <AssistantForm
      ref="assistantForm"
      :mode="type"
      :assistant="selectedAssistant"
      @submit="handleSubmit"
      @cancel="handleCancel"
    />
    <template #footer />
  </Dialog>
</template>
