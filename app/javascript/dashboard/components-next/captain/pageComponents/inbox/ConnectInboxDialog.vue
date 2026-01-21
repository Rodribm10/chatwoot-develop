<script setup>
import { ref, computed } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import ConnectInboxForm from './ConnectInboxForm.vue';

const props = defineProps({
  assistantId: {
    type: Number,
    required: true,
  },
  type: {
    type: String,
    default: 'create',
  },
  inbox: {
    type: Object,
    default: null,
  },
});
const emit = defineEmits(['close']);
const { t } = useI18n();
const store = useStore();

const dialogRef = ref(null);
const connectForm = ref(null);

const i18nKey = computed(() =>
  props.type === 'edit' ? 'CAPTAIN.INBOXES.EDIT' : 'CAPTAIN.INBOXES.CREATE'
);

const handleSubmit = async payload => {
  try {
    const action =
      props.type === 'edit' ? 'captainInboxes/update' : 'captainInboxes/create';
    await store.dispatch(action, payload);
    useAlert(t(`${i18nKey.value}.SUCCESS_MESSAGE`));
    dialogRef.value.close();
  } catch (error) {
    const errorMessage = error?.message || t(`${i18nKey.value}.ERROR_MESSAGE`);
    useAlert(errorMessage);
  }
};

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
  <Dialog
    ref="dialogRef"
    :type="type"
    :title="$t(`${i18nKey}.TITLE`)"
    :description="$t('CAPTAIN.INBOXES.FORM_DESCRIPTION')"
    :show-cancel-button="false"
    :show-confirm-button="false"
    @close="handleClose"
  >
    <ConnectInboxForm
      ref="connectForm"
      :assistant-id="assistantId"
      :inbox="inbox"
      @submit="handleSubmit"
      @cancel="handleCancel"
    />
    <template #footer />
  </Dialog>
</template>
