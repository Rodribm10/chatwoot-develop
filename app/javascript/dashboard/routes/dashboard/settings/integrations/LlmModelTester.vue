<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useIntegrationHook } from 'dashboard/composables/useIntegrationHook';
import IntegrationsAPI from 'dashboard/api/integrations';
import Button from 'dashboard/components-next/button/Button.vue';
import { LLM_MODELS } from 'dashboard/constants/llmModels';

const props = defineProps({
  integrationId: {
    type: String,
    required: true,
  },
});

const { t } = useI18n();
const store = useStore();
const { integration, hasConnectedHooks } = useIntegrationHook(
  props.integrationId
);

const testingModel = ref('');

const hook = computed(() => integration.value.hooks?.[0]);
const modelTests = computed(() => hook.value?.settings?.model_tests || {});
const validatedModels = computed(
  () => hook.value?.settings?.validated_models || []
);

const modelOptions = computed(() => LLM_MODELS[props.integrationId] || []);

const statusFor = model => {
  const entry = modelTests.value[model];
  if (!entry)
    return {
      label: t('INTEGRATION_SETTINGS.OPEN_AI.TESTER.STATUS.NOT_TESTED'),
      ok: false,
    };
  return entry.success
    ? { label: t('INTEGRATION_SETTINGS.OPEN_AI.TESTER.STATUS.OK'), ok: true }
    : {
        label:
          entry.error || t('INTEGRATION_SETTINGS.OPEN_AI.TESTER.STATUS.FAIL'),
        ok: false,
      };
};

const testModel = async model => {
  try {
    testingModel.value = model;
    await IntegrationsAPI.testLlmModel({
      provider: props.integrationId,
      model,
    });
    await store.dispatch('integrations/get', props.integrationId);
    useAlert(
      t('INTEGRATION_SETTINGS.OPEN_AI.TESTER.STATUS.SUCCESS', { model })
    );
  } catch (error) {
    const errorMessage =
      error?.response?.data?.error ||
      error?.response?.data?.message ||
      t('INTEGRATION_SETTINGS.OPEN_AI.TESTER.STATUS.ERROR');
    useAlert(errorMessage);
  } finally {
    testingModel.value = '';
  }
};
</script>

<template>
  <div
    class="outline outline-n-container outline-1 bg-n-alpha-3 rounded-md shadow p-4"
  >
    <div class="flex items-center justify-between">
      <div>
        <h4 class="text-base font-semibold text-n-slate-12">
          {{ t('INTEGRATION_SETTINGS.OPEN_AI.TESTER.TITLE') }}
        </h4>
        <p class="text-sm text-n-slate-11">
          {{ t('INTEGRATION_SETTINGS.OPEN_AI.TESTER.DESCRIPTION') }}
        </p>
      </div>
      <div v-if="!hasConnectedHooks" class="text-sm text-n-slate-11">
        {{ t('INTEGRATION_SETTINGS.OPEN_AI.TESTER.CONNECT_BEFORE_TEST') }}
      </div>
    </div>

    <div v-if="hasConnectedHooks" class="mt-4">
      <div
        v-for="model in modelOptions"
        :key="model.value"
        class="flex items-center justify-between py-2 border-b border-n-weak"
      >
        <div class="flex flex-col">
          <span class="text-sm text-n-slate-12 flex items-center gap-2">
            {{ model.label }}
            <span
              v-if="statusFor(model.value).ok"
              class="text-xs bg-n-teal-9/10 text-n-teal-11 px-2 py-0.5 rounded-full"
            >
              {{ t('INTEGRATION_SETTINGS.OPEN_AI.TESTER.TESTED_LABEL') }}
            </span>
          </span>
          <span class="text-xs text-n-slate-11">{{ model.value }}</span>
        </div>
        <div class="flex items-center gap-3">
          <span
            class="text-xs"
            :class="
              statusFor(model.value).ok ? 'text-n-teal-9' : 'text-n-slate-11'
            "
          >
            {{ statusFor(model.value).label }}
          </span>
          <Button
            xs
            faded
            blue
            :label="
              testingModel === model.value
                ? t('INTEGRATION_SETTINGS.OPEN_AI.TESTER.BUTTON.TESTING')
                : t('INTEGRATION_SETTINGS.OPEN_AI.TESTER.BUTTON.TEST')
            "
            :disabled="Boolean(testingModel) && testingModel !== model.value"
            @click="testModel(model.value)"
          />
        </div>
      </div>
      <div class="mt-3 text-xs text-n-slate-11">
        {{ t('INTEGRATION_SETTINGS.OPEN_AI.TESTER.VALIDATED_COUNT') }}
        {{ validatedModels.length || 0 }}
      </div>
    </div>
    <div v-else class="mt-4 text-sm text-n-slate-11">
      {{ t('INTEGRATION_SETTINGS.OPEN_AI.TESTER.CONNECT_REQUIRED') }}
    </div>
  </div>
</template>
