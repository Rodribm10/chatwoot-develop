<script setup>
import { reactive, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { minLength } from '@vuelidate/validators';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { useAccount } from 'dashboard/composables/useAccount';

import Button from 'dashboard/components-next/button/Button.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';

const props = defineProps({
  assistant: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['submit']);

const { t } = useI18n();
const { isCloudFeatureEnabled } = useAccount();

const isCaptainV2Enabled = computed(() =>
  isCloudFeatureEnabled(FEATURE_FLAGS.CAPTAIN_V2)
);

const initialState = {
  handoffMessage: '',
  resolutionMessage: '',
  instructions: '',
  playbook: '',
  temperature: 1,
  distanceThreshold: 0.35,
  maxRagResults: 3,
};

const state = reactive({ ...initialState });

const validationRules = {
  handoffMessage: { minLength: minLength(1) },
  resolutionMessage: { minLength: minLength(1) },
  instructions: { minLength: minLength(1) },
  playbook: { minLength: minLength(1) },
};

const v$ = useVuelidate(validationRules, state);

const getErrorMessage = field => {
  return v$.value[field].$error ? v$.value[field].$errors[0].$message : '';
};

const formErrors = computed(() => ({
  handoffMessage: getErrorMessage('handoffMessage'),
  resolutionMessage: getErrorMessage('resolutionMessage'),
  instructions: getErrorMessage('instructions'),
  playbook: getErrorMessage('playbook'),
}));

const updateStateFromAssistant = assistant => {
  const { config = {} } = assistant;
  state.handoffMessage = config.handoff_message || '';
  state.resolutionMessage = config.resolution_message || '';
  state.instructions = config.instructions || '';
  state.playbook = config.playbook || '';
  state.temperature = config.temperature !== undefined ? config.temperature : 1;
  state.distanceThreshold =
    config.distance_threshold !== undefined ? config.distance_threshold : 0.35;
  state.maxRagResults = config.max_rag_results || 3;
};

const handleSystemMessagesUpdate = async () => {
  const validations = [
    v$.value.handoffMessage.$validate(),
    v$.value.resolutionMessage.$validate(),
  ];

  if (!isCaptainV2Enabled.value) {
    validations.push(v$.value.instructions.$validate());
  }

  const result = await Promise.all(validations).then(results =>
    results.every(Boolean)
  );
  if (!result) return;

  const payload = {
    config: {
      ...props.assistant.config,
      handoff_message: state.handoffMessage,
      resolution_message: state.resolutionMessage,
      temperature: state.temperature !== undefined ? state.temperature : 1,
      playbook: state.playbook,
      distance_threshold: state.distanceThreshold,
      max_rag_results: state.maxRagResults,
    },
  };

  if (!isCaptainV2Enabled.value) {
    payload.config.instructions = state.instructions;
  }

  emit('submit', payload);
};

watch(
  () => props.assistant,
  newAssistant => {
    if (newAssistant) updateStateFromAssistant(newAssistant);
  },
  { immediate: true }
);
</script>

<template>
  <div class="flex flex-col gap-6">
    <Editor
      v-model="state.handoffMessage"
      :label="t('CAPTAIN.ASSISTANTS.FORM.HANDOFF_MESSAGE.LABEL')"
      :placeholder="t('CAPTAIN.ASSISTANTS.FORM.HANDOFF_MESSAGE.PLACEHOLDER')"
      :message="formErrors.handoffMessage"
      :message-type="formErrors.handoffMessage ? 'error' : 'info'"
      class="z-0"
    />

    <Editor
      v-model="state.resolutionMessage"
      :label="t('CAPTAIN.ASSISTANTS.FORM.RESOLUTION_MESSAGE.LABEL')"
      :placeholder="t('CAPTAIN.ASSISTANTS.FORM.RESOLUTION_MESSAGE.PLACEHOLDER')"
      :message="formErrors.resolutionMessage"
      :message-type="formErrors.resolutionMessage ? 'error' : 'info'"
      class="z-0"
    />

    <Editor
      v-if="!isCaptainV2Enabled"
      v-model="state.instructions"
      :label="t('CAPTAIN.ASSISTANTS.FORM.INSTRUCTIONS.LABEL')"
      :placeholder="t('CAPTAIN.ASSISTANTS.FORM.INSTRUCTIONS.PLACEHOLDER')"
      :message="formErrors.instructions"
      :max-length="20000"
      :message-type="formErrors.instructions ? 'error' : 'info'"
      class="z-0"
    />

    <Editor
      v-model="state.playbook"
      :label="t('CAPTAIN.ASSISTANTS.FORM.PLAYBOOK.LABEL')"
      :placeholder="t('CAPTAIN.ASSISTANTS.FORM.PLAYBOOK.PLACEHOLDER')"
      :message="formErrors.playbook"
      :max-length="20000"
      :message-type="formErrors.playbook ? 'error' : 'info'"
      class="z-0"
    />

    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
      <div class="flex flex-col gap-2">
        <label class="text-sm font-medium text-n-slate-12">
          {{ t('CAPTAIN.ASSISTANTS.FORM.TEMPERATURE.LABEL') }}
        </label>
        <div class="flex items-center gap-4">
          <input
            v-model="state.temperature"
            type="range"
            min="0"
            max="1"
            step="0.1"
            class="w-full h-1.5 bg-n-slate-3 rounded-lg appearance-none cursor-pointer"
          />
          <span class="text-sm font-medium text-n-slate-12 w-8 text-right">{{
            state.temperature
          }}</span>
        </div>
        <p class="text-xs text-n-slate-11 italic">
          {{ t('CAPTAIN.ASSISTANTS.FORM.TEMPERATURE.DESCRIPTION') }}
        </p>
      </div>

      <div class="flex flex-col gap-2">
        <label class="text-sm font-medium text-n-slate-12">
          {{ t('CAPTAIN.ASSISTANTS.FORM.DISTANCE_THRESHOLD.LABEL') }}
        </label>
        <div class="flex items-center gap-4">
          <input
            v-model="state.distanceThreshold"
            type="range"
            min="0"
            max="1"
            step="0.01"
            class="w-full h-1.5 bg-n-slate-3 rounded-lg appearance-none cursor-pointer"
          />
          <span class="text-sm font-medium text-n-slate-12 w-8 text-right">{{
            state.distanceThreshold
          }}</span>
        </div>
        <p class="text-xs text-n-slate-11 italic">
          {{ t('CAPTAIN.ASSISTANTS.FORM.DISTANCE_THRESHOLD.DESCRIPTION') }}
        </p>
      </div>
    </div>

    <div class="max-w-[200px]">
      <label class="text-sm font-medium text-n-slate-12 mb-2 block">
        {{ t('CAPTAIN.ASSISTANTS.FORM.MAX_RAG_RESULTS.LABEL') }}
      </label>
      <input
        v-model="state.maxRagResults"
        type="number"
        min="1"
        max="10"
        class="w-full px-3 py-2 rounded-lg bg-n-alpha-black2 text-sm outline outline-1 outline-n-weak focus:outline-n-strong"
      />
    </div>

    <div>
      <Button
        :label="t('CAPTAIN.ASSISTANTS.FORM.UPDATE')"
        @click="handleSystemMessagesUpdate"
      />
    </div>
  </div>
</template>
