<script setup>
import { reactive, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';

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

const initialState = {
  name: '',
  description: '',
  productName: '',
  llmProvider: 'openai',
  llmModel: '',
  apiKey: '',
  features: {
    conversationFaqs: false,
    memories: false,
    citations: false,
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
  state.llmProvider = assistant.llm_provider || 'openai';
  state.llmModel = assistant.llm_model || '';
  state.apiKey = assistant.api_key;
  state.features = {
    conversationFaqs: config.feature_faq || false,
    memories: config.feature_memory || false,
    citations: config.feature_citation || false,
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
      feature_faq: state.features.conversationFaqs,
      feature_memory: state.features.memories,
      feature_citation: state.features.citations,
    },
  };

  emit('submit', payload);
};

// Provider options
const llmProviderOptions = [
  { value: 'openai', label: 'OpenAI' },
  { value: 'gemini', label: 'Google Gemini' },
];

const llmProviderLabel = computed(() => {
  const option = llmProviderOptions.find(
    opt => opt.value === state.llmProvider
  );
  return option ? option.label : 'Selecione um provedor';
});

// Model options based on provider
const llmModelOptions = computed(() => {
  if (state.llmProvider === 'openai') {
    return [
      { value: 'gpt-5.2', label: 'GPT-5.2 (Mais Potente)' },
      { value: 'gpt-5.2-pro', label: 'GPT-5.2 Pro (Premium)' },
      { value: 'gpt-5.1', label: 'GPT-5.1' },
      { value: 'gpt-5', label: 'GPT-5' },
      { value: 'gpt-5-mini', label: 'GPT-5 Mini (Custo/Beneficio)' },
      { value: 'gpt-5-nano', label: 'GPT-5 Nano (Super Economico)' },
      { value: 'gpt-4.1', label: 'GPT-4.1 (Estavel)' },
      { value: 'gpt-4.1-mini', label: 'GPT-4.1 Mini (Barato)' },
      { value: 'gpt-4o-mini', label: 'GPT-4o Mini (Rapido)' },
    ];
  }
  if (state.llmProvider === 'gemini') {
    return [
      { value: 'gemini-3-pro', label: 'Gemini 3 Pro (Mais Potente)' },
      { value: 'gemini-3-flash', label: 'Gemini 3 Flash (Rapido)' },
      { value: 'gemini-2.5-pro', label: 'Gemini 2.5 Pro (Equilibrado)' },
      {
        value: 'gemini-2.5-flash',
        label: 'Gemini 2.5 Flash (Rapido/Economico)',
      },
      {
        value: 'gemini-2.5-flash-lite',
        label: 'Gemini 2.5 Flash Lite (Super Economico)',
      },
      { value: 'gemini-2.0-flash', label: 'Gemini 2.0 Flash (Leve)' },
      {
        value: 'gemini-2.0-flash-lite',
        label: 'Gemini 2.0 Flash Lite (Economico)',
      },
    ];
  }
  return [];
});

const llmModelLabel = computed(() => {
  const option = llmModelOptions.value.find(
    opt => opt.value === state.llmModel
  );
  return option ? option.label : state.llmModel || 'Selecione um modelo';
});

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
        </div>
      </div>
      <Input
        v-model="state.apiKey"
        :label="t('CAPTAIN.ASSISTANTS.FORM.API_KEY.LABEL')"
        :placeholder="t('CAPTAIN.ASSISTANTS.FORM.API_KEY.PLACEHOLDER')"
        type="password"
      />
    </div>

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
