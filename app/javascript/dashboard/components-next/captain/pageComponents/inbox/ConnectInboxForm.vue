<script setup>
import { reactive, computed, onMounted, watch } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { useMapGetter } from 'dashboard/composables/store';

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
const route = useRoute();

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

const accountId = computed(() => {
  return route.params.accountId || window.chatwootConfig?.account_id;
});

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
    ? // eslint-disable-next-line @intlify/vue-i18n/no-dynamic-keys
      t(`CAPTAIN.INBOXES.FORM.${errorKey}.ERROR`)
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

const fetchUnits = async () => {
  if (!accountId.value) {
    return;
  }

  if (!window.axios) {
    return;
  }

  try {
    const url = `/api/v1/accounts/${accountId.value}/captain/units`;
    const { data } = await window.axios.get(url);
    units.push(...data);
  } catch (error) {
    // Ignore error
  }
};

onMounted(() => {
  fetchUnits();
});

watch(accountId, () => {
  fetchUnits();
});
</script>

<template>
  <!-- eslint-disable vue/no-bare-strings-in-template -->
  <!-- eslint-disable @intlify/vue-i18n/no-raw-text -->
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
        <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
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
        <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
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
