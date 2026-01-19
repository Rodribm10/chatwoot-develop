<script setup>
import { reactive, computed, watch, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { LLM_MODELS, LLM_PROVIDERS } from 'dashboard/constants/llmModels';

import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';
import SelectMenu from 'dashboard/components-next/selectmenu/SelectMenu.vue';

const props = defineProps({
  assistant: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['submit']);

const { t } = useI18n();
const store = useStore();
const integrationGetter = useMapGetter('integrations/getIntegration');

const initialState = {
  name: '',
  description: '',
  productName: '',
  roleName: '',
  llmProvider: 'openai',
  llmModel: '',
  apiKey: '',
  features: {
    conversationFaqs: false,
    memories: false,
    citations: false,
    handoffOnSentiment: false,
    allowHandoff: true,
  },
};

const state = reactive({ ...initialState });

const validationRules = {
  name: { required, minLength: minLength(1) },
  description: { required, minLength: minLength(1) },
  productName: { required, minLength: minLength(1) },
};

const v$ = useVuelidate(validationRules, state);

const getErrorMessage = field => {
  return v$.value[field].$error ? v$.value[field].$errors[0].$message : '';
};

const formErrors = computed(() => ({
  name: getErrorMessage('name'),
  description: getErrorMessage('description'),
  productName: getErrorMessage('productName'),
}));

const updateStateFromAssistant = assistant => {
  if (!assistant) return;
  const { config = {} } = assistant;
  state.name = assistant.name;
  state.description = assistant.description;
  state.productName = config.product_name;
  state.roleName = config.role_name;
  state.llmProvider = assistant.llm_provider || 'openai';
  state.llmModel = assistant.llm_model || '';
  state.apiKey = assistant.api_key;
  state.features = {
    conversationFaqs: config.feature_faq || false,
    memories: config.feature_memory || false,
    citations: config.feature_citation || false,
    handoffOnSentiment: config.handoff_on_sentiment || false,
    allowHandoff: config.allow_handoff !== false,
  };
};

const handleBasicInfoUpdate = async () => {
  const result = await Promise.all([
    v$.value.name.$validate(),
    v$.value.description.$validate(),
    v$.value.productName.$validate(),
  ]).then(results => results.every(Boolean));
  if (!result) return;

  const payload = {
    name: state.name,
    description: state.description,
    llm_provider: state.llmProvider,
    llm_model: state.llmModel,
    api_key: state.apiKey,
    config: {
      ...props.assistant.config,
      product_name: state.productName,
      role_name: state.roleName,
      feature_faq: state.features.conversationFaqs,
      feature_memory: state.features.memories,
      feature_citation: state.features.citations,
      handoff_on_sentiment: state.features.handoffOnSentiment,
      allow_handoff: state.features.allowHandoff,
    },
  };

  emit('submit', payload);
};

// Provider options
const llmProviderOptions = LLM_PROVIDERS;

const llmProviderLabel = computed(() => {
  const option = llmProviderOptions.find(
    opt => opt.value === state.llmProvider
  );
  return option ? option.label : 'Selecione um provedor';
});

const validatedModelsFor = provider => {
  const integration = integrationGetter.value(provider) || {};
  const hook = integration.hooks?.[0];
  return hook?.settings?.validated_models || [];
};

// Model options based on provider
const llmModelOptions = computed(() => {
  const baseOptions = LLM_MODELS[state.llmProvider] || [];
  const validatedModels = validatedModelsFor(state.llmProvider);
  if (!validatedModels.length) return baseOptions;

  return baseOptions.filter(option => validatedModels.includes(option.value));
});

const llmModelLabel = computed(() => {
  const option = llmModelOptions.value.find(
    opt => opt.value === state.llmModel
  );
  return option ? option.label : state.llmModel || 'Selecione um modelo';
});

const modelStatusLabel = computed(() => {
  const validatedModels = validatedModelsFor(state.llmProvider);
  if (!state.llmModel) return 'Selecione um modelo';
  if (!validatedModels.length)
    return 'Nenhum modelo validado para este provedor';
  return validatedModels.includes(state.llmModel)
    ? 'Modelo validado'
    : 'Modelo nao validado';
});

watch(
  () => props.assistant,
  newAssistant => {
    if (newAssistant) updateStateFromAssistant(newAssistant);
  },
  { immediate: true }
);

onMounted(() => {
  store.dispatch('integrations/get', 'openai');
  store.dispatch('integrations/get', 'gemini');
});
</script>

<template>
  <!-- eslint-disable vue/no-bare-strings-in-template -->
  <div class="flex flex-col gap-6">
    <Input
      v-model="state.name"
      :label="t('CAPTAIN.ASSISTANTS.FORM.NAME.LABEL')"
      :placeholder="t('CAPTAIN.ASSISTANTS.FORM.NAME.PLACEHOLDER')"
      :message="formErrors.name"
      :message-type="formErrors.name ? 'error' : 'info'"
    />

    <Input
      v-model="state.productName"
      :label="t('CAPTAIN.ASSISTANTS.FORM.PRODUCT_NAME.LABEL')"
      :placeholder="t('CAPTAIN.ASSISTANTS.FORM.PRODUCT_NAME.PLACEHOLDER')"
      :message="formErrors.productName"
      :message-type="formErrors.productName ? 'error' : 'info'"
    />

    <Editor
      v-model="state.description"
      :label="t('CAPTAIN.ASSISTANTS.FORM.DESCRIPTION.LABEL')"
      :placeholder="t('CAPTAIN.ASSISTANTS.FORM.DESCRIPTION.PLACEHOLDER')"
      :message="formErrors.description"
      :message-type="formErrors.description ? 'error' : 'info'"
      class="z-0"
    />

    <div class="flex flex-col gap-4 py-2">
      <h6 class="text-sm font-medium text-n-slate-12">
        {{ t('CAPTAIN.ASSISTANTS.FORM.SECTIONS.LLM_CONFIG') }}
      </h6>
      <div class="flex gap-4">
        <div class="w-1/2 flex flex-col gap-2">
          <label class="text-sm font-medium text-n-slate-12">
            {{ t('CAPTAIN.ASSISTANTS.FORM.LLM_PROVIDER.LABEL') }}
          </label>
          <SelectMenu
            v-model="state.llmProvider"
            :options="llmProviderOptions"
            :label="llmProviderLabel"
            sub-menu-position="bottom"
          />
        </div>
        <div class="w-1/2 flex flex-col gap-2">
          <label class="text-sm font-medium text-n-slate-12">
            {{ t('CAPTAIN.ASSISTANTS.FORM.LLM_MODEL.LABEL') }}
          </label>
          <SelectMenu
            v-model="state.llmModel"
            :options="llmModelOptions"
            :label="llmModelLabel"
            sub-menu-position="bottom"
          />
          <p class="text-xs text-n-slate-11">
            {{ modelStatusLabel }}
          </p>
        </div>
      </div>
      <Input
        v-model="state.apiKey"
        :label="t('CAPTAIN.ASSISTANTS.FORM.API_KEY.LABEL')"
        :placeholder="t('CAPTAIN.ASSISTANTS.FORM.API_KEY.PLACEHOLDER')"
        type="password"
      />
    </div>

    <Input
      v-model="state.roleName"
      :label="t('CAPTAIN.ASSISTANTS.FORM.ROLE_NAME.LABEL')"
      :placeholder="t('CAPTAIN.ASSISTANTS.FORM.ROLE_NAME.PLACEHOLDER')"
      :message="formErrors.roleName"
      :message-type="formErrors.roleName ? 'error' : 'info'"
    />

    <div class="flex flex-col gap-2">
      <label class="text-sm font-medium text-n-slate-12">
        {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.TITLE') }}
      </label>
      <div class="flex flex-col gap-2">
        <label class="flex items-center gap-2">
          <input v-model="state.features.conversationFaqs" type="checkbox" />
          {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.ALLOW_CONVERSATION_FAQS') }}
        </label>
        <label class="flex items-center gap-2">
          <input v-model="state.features.memories" type="checkbox" />
          {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.ALLOW_MEMORIES') }}
        </label>
        <label class="flex items-center gap-2">
          <input v-model="state.features.citations" type="checkbox" />
          {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.ALLOW_CITATIONS') }}
        </label>
        <label class="flex items-center gap-2">
          <input v-model="state.features.handoffOnSentiment" type="checkbox" />
          {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.ALLOW_SENTIMENT_HANDOFF') }}
        </label>
        <label class="flex items-center gap-2">
          <input v-model="state.features.allowHandoff" type="checkbox" />
          {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.ALLOW_HANDOFF') }}
        </label>
      </div>
    </div>

    <div>
      <Button
        :label="t('CAPTAIN.ASSISTANTS.FORM.UPDATE')"
        @click="handleBasicInfoUpdate"
      />
    </div>
  </div>
</template>
