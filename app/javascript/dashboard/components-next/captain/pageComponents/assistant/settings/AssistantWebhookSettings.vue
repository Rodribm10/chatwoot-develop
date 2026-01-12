<script setup>
import { reactive, computed, watch, ref, useTemplateRef } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { requiredIf, url } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import CaptainAssistantAPI from 'dashboard/api/captain/assistant';
import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import HeaderRow from 'dashboard/components-next/captain/pageComponents/customTool/HeaderRow.vue';

const props = defineProps({
  assistant: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['submit']);

const { t } = useI18n();
const isTesting = ref(false);

const state = reactive({
  enabled: false,
  url: '',
  headers: [],
  retry_attempts: 3,
  timeout_seconds: 5,
});

const headersRef = useTemplateRef('headersRef');

const DEFAULT_HEADER = { key: '', value: '' };

const validationRules = {
  url: {
    required: requiredIf(() => state.enabled),
    url,
  },
};

const v$ = useVuelidate(validationRules, state);

const updateStateFromAssistant = assistant => {
  const config = assistant?.handoff_webhook_config || {};
  state.enabled = !!config.enabled;
  state.url = config.url || '';
  state.retry_attempts = config.retry_attempts ?? 3;
  state.timeout_seconds = config.timeout_seconds ?? 5;
  state.headers = Object.entries(config.headers || {}).map(([key, value]) => ({
    key,
    value,
  }));
};

watch(
  () => props.assistant,
  assistant => {
    if (assistant) updateStateFromAssistant(assistant);
  },
  { immediate: true }
);

const addHeader = () => {
  state.headers.push({ ...DEFAULT_HEADER });
};

const removeHeader = index => {
  state.headers.splice(index, 1);
};

const isHeadersValid = () => {
  if (!headersRef.value || headersRef.value.length === 0) {
    return true;
  }
  return headersRef.value.every(header => header.validate());
};

const isFormValid = computed(() => {
  if (!state.enabled) return true;
  return !v$.value.$invalid && isHeadersValid();
});

const buildHeadersPayload = () => {
  if (!state.headers.length) return {};

  return state.headers.reduce((acc, header) => {
    if (header.key && header.value) {
      acc[header.key] = header.value;
    }
    return acc;
  }, {});
};

const handleSubmit = async () => {
  const isValid = await v$.value.$validate();
  if (!isValid || !isHeadersValid()) return;

  emit('submit', {
    handoff_webhook_config: {
      enabled: state.enabled,
      url: state.url,
      retry_attempts: state.retry_attempts,
      timeout_seconds: state.timeout_seconds,
      headers: buildHeadersPayload(),
    },
  });
};

const testWebhook = async () => {
  isTesting.value = true;
  try {
    await CaptainAssistantAPI.testWebhook(props.assistant.id);
    useAlert(t('CAPTAIN.ASSISTANTS.FORM.WEBHOOK.TEST_SENT'));
  } catch (error) {
    const message = error?.response?.data?.error || error.message;
    useAlert(message);
  } finally {
    isTesting.value = false;
  }
};
</script>

<template>
  <!-- eslint-disable vue/no-bare-strings-in-template -->
  <div class="flex flex-col gap-6">
    <div class="flex items-center justify-between">
      <div>
        <h3 class="text-lg font-semibold text-n-slate-12">
          {{ t('CAPTAIN.ASSISTANTS.FORM.WEBHOOK.TITLE') }}
        </h3>
        <p class="text-sm text-n-slate-11">
          {{ t('CAPTAIN.ASSISTANTS.FORM.WEBHOOK.DESCRIPTION') }}
        </p>
      </div>
      <Switch v-model="state.enabled" />
    </div>

    <div v-if="state.enabled" class="flex flex-col gap-4">
      <Input
        v-model="state.url"
        :label="t('CAPTAIN.ASSISTANTS.FORM.WEBHOOK.URL_LABEL')"
        :placeholder="t('CAPTAIN.ASSISTANTS.FORM.WEBHOOK.URL_PLACEHOLDER')"
        required
      />

      <div class="flex flex-col gap-2">
        <label class="text-sm font-medium text-n-slate-12">
          {{ t('CAPTAIN.ASSISTANTS.FORM.WEBHOOK.HEADERS_LABEL') }}
        </label>
        <p class="text-xs text-n-slate-11">
          {{ t('CAPTAIN.ASSISTANTS.FORM.WEBHOOK.HEADERS_HELP') }}
        </p>
        <ul v-if="state.headers.length" class="grid gap-2 list-none">
          <HeaderRow
            v-for="(header, index) in state.headers"
            :key="index"
            ref="headersRef"
            v-model:key="header.key"
            v-model:value="header.value"
            @remove="removeHeader(index)"
          />
        </ul>
        <Button
          :label="t('CAPTAIN.ASSISTANTS.FORM.WEBHOOK.ADD_HEADER')"
          variant="faded"
          color="slate"
          @click="addHeader"
        />
      </div>

      <div class="grid grid-cols-2 gap-4">
        <Input
          v-model.number="state.retry_attempts"
          type="number"
          :label="t('CAPTAIN.ASSISTANTS.FORM.WEBHOOK.RETRY_LABEL')"
          min="0"
          max="5"
        />
        <Input
          v-model.number="state.timeout_seconds"
          type="number"
          :label="t('CAPTAIN.ASSISTANTS.FORM.WEBHOOK.TIMEOUT_LABEL')"
          min="1"
          max="30"
        />
      </div>
    </div>

    <div class="flex gap-2">
      <Button
        :label="t('CAPTAIN.ASSISTANTS.FORM.UPDATE')"
        :disabled="!isFormValid"
        @click="handleSubmit"
      />
      <Button
        v-if="state.enabled"
        :label="t('CAPTAIN.ASSISTANTS.FORM.WEBHOOK.TEST_BUTTON')"
        variant="faded"
        color="slate"
        :is-loading="isTesting"
        :disabled="isTesting"
        @click="testWebhook"
      />
    </div>
  </div>
</template>
