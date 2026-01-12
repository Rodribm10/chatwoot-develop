<script setup>
import { reactive, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { useMapGetter } from 'dashboard/composables/store';
import axios from 'axios';

import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';

const props = defineProps({
  assistantId: {
    type: Number,
    required: true,
  },
});

const emit = defineEmits(['submit', 'cancel']);

const { t } = useI18n();

const formState = {
  uiFlags: useMapGetter('captainInboxes/getUIFlags'),
  inboxes: useMapGetter('inboxes/getInboxes'),
  captainInboxes: useMapGetter('captainInboxes/getRecords'),
};

const initialState = {
  inboxId: null,
  captainUnitId: null,
};

const state = reactive({ ...initialState });
const units = reactive([]);

const validationRules = {
  inboxId: { required },
};

const inboxList = computed(() => {
  const captainInboxIds = formState.captainInboxes.value.map(inbox => inbox.id);

  return formState.inboxes.value
    .filter(inbox => !captainInboxIds.includes(inbox.id))
    .map(inbox => ({
      value: inbox.id,
      label: inbox.name,
    }));
});

const unitList = computed(() => {
  return units.map(unit => ({
    value: unit.id,
    label: unit.name,
  }));
});

const v$ = useVuelidate(validationRules, state);

const isLoading = computed(() => formState.uiFlags.value.creatingItem);

const getErrorMessage = (field, errorKey) => {
  return v$.value[field].$error
    ? t(`CAPTAIN.INBOXES.FORM.${errorKey}.ERROR`)
    : '';
};

const formErrors = computed(() => ({
  inboxId: getErrorMessage('inboxId', 'INBOX'),
}));

const handleCancel = () => emit('cancel');

const prepareInboxPayload = () => ({
  inboxId: state.inboxId,
  captainUnitId: state.captainUnitId,
  assistantId: props.assistantId,
});

const handleSubmit = async () => {
  const isFormValid = await v$.value.$validate();
  if (!isFormValid) {
    return;
  }

  emit('submit', prepareInboxPayload());
};

onMounted(async () => {
  try {
    const { data } = await axios.get('/api/v1/accounts/captain/units');
    units.push(...data);
  } catch (error) {
    // Silent fail or alert
  }
});
</script>

<template>
  <!-- eslint-disable vue/no-bare-strings-in-template -->
  <form class="flex flex-col gap-4" @submit.prevent="handleSubmit">
    <div class="flex flex-col gap-1">
      <label for="inbox" class="mb-0.5 text-sm font-medium text-n-slate-12">
        {{ t('CAPTAIN.INBOXES.FORM.INBOX.LABEL') }}
      </label>
      <ComboBox
        id="inbox"
        v-model="state.inboxId"
        :options="inboxList"
        :has-error="!!formErrors.inboxId"
        :placeholder="t('CAPTAIN.INBOXES.FORM.INBOX.PLACEHOLDER')"
        class="[&>div>button]:bg-n-alpha-black2 [&>div>button:not(.focused)]:dark:outline-n-weak [&>div>button:not(.focused)]:hover:!outline-n-slate-6"
        :message="formErrors.inboxId"
      />
    </div>

    <!-- Unit Selection -->
    <div class="flex flex-col gap-1">
      <label for="unit" class="mb-0.5 text-sm font-medium text-n-slate-12">
        Unidade (Opcional - Pix)
      </label>
      <ComboBox
        id="unit"
        v-model="state.captainUnitId"
        :options="unitList"
        placeholder="Selecione a unidade financeira"
        class="[&>div>button]:bg-n-alpha-black2 [&>div>button:not(.focused)]:dark:outline-n-weak [&>div>button:not(.focused)]:hover:!outline-n-slate-6"
      />
      <span class="text-xs text-n-slate-11">
        Vincule a uma unidade para ativar Pix automático.
      </span>
    </div>

    <div class="flex items-center justify-between w-full gap-3">
      <Button
        type="button"
        variant="faded"
        color="slate"
        :label="t('CAPTAIN.FORM.CANCEL')"
        class="w-full bg-n-alpha-2 text-n-blue-text hover:bg-n-alpha-3"
        @click="handleCancel"
      />
      <Button
        type="submit"
        :label="t('CAPTAIN.FORM.CREATE')"
        class="w-full"
        :is-loading="isLoading"
        :disabled="isLoading"
      />
    </div>
  </form>
</template>
