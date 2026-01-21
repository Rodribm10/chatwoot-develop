<script setup>
/* eslint-disable @intlify/vue-i18n/no-raw-text, vue/no-bare-strings-in-template, @intlify/vue-i18n/no-dynamic-keys */
import { computed, reactive, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import { useVuelidate } from '@vuelidate/core';
import { vOnClickOutside } from '@vueuse/components';
import { required, minLength } from '@vuelidate/validators';
import { useMapGetter } from 'dashboard/composables/store';

import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';
import TagMultiSelectComboBox from 'dashboard/components-next/combobox/TagMultiSelectComboBox.vue';

import ScenariosAPI from 'dashboard/api/captain/scenarios';
import { useRoute } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import { SCENARIO_TEMPLATES } from 'dashboard/routes/dashboard/jasmine/data/templates';

const props = defineProps({
  triggerLabel: {
    type: String,
    default: 'CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.CREATE',
  },
  startWithTemplates: {
    type: Boolean,
    default: false,
  },
  triggerIcon: {
    type: String,
    default: '',
  },
  triggerFaded: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['add']);

const { t } = useI18n();

const [showPopover, togglePopover] = useToggle();

const state = reactive({
  id: '',
  title: '',
  description: '',
  instruction: '',
  trigger_keywords: '',
  tools: [],
});

const allTools = useMapGetter('captainTools/getRecords');
const route = useRoute();
const isSuggesting = ref(false);
const showTemplateSelect = ref(false);

watch(showPopover, val => {
  if (val && props.startWithTemplates) {
    showTemplateSelect.value = true;
  }
});

const toolOptions = computed(() => {
  return allTools.value.map(tool => ({
    label: tool.title,
    value: tool.id,
  }));
});

const rules = {
  title: { required, minLength: minLength(1) },
  description: { required },
  instruction: { required },
};

const v$ = useVuelidate(rules, state);

const titleError = computed(() =>
  v$.value.title.$error
    ? t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.TITLE.ERROR')
    : ''
);

const descriptionError = computed(() =>
  v$.value.description.$error
    ? t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.DESCRIPTION.ERROR')
    : ''
);

const instructionError = computed(() =>
  v$.value.instruction.$error
    ? t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.INSTRUCTION.ERROR')
    : ''
);

const resetState = () => {
  Object.assign(state, {
    id: '',
    title: '',
    description: '',
    instruction: '',
    tools: [],
  });
};

const onClickAdd = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  await emit('add', state);
  resetState();
  togglePopover(false);
};

const onClickCancel = () => {
  togglePopover(false);
};

const onSuggestTriggers = async () => {
  if (!state.instruction && !state.title) {
    useAlert(
      t(
        'CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.TRIGGER_KEYWORDS.SUGGEST_ERROR'
      )
    );
    return;
  }

  isSuggesting.value = true;
  try {
    const assistantId = route.params.assistantId;
    const response = await ScenariosAPI.suggestTriggers({
      assistantId,
      title: state.title,
      description: state.description,
      instruction: state.instruction,
    });

    if (response.data.keywords) {
      state.trigger_keywords = response.data.keywords;
      useAlert(
        t(
          'CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.TRIGGER_KEYWORDS.SUGGEST_SUCCESS'
        )
      );
    }
  } catch (error) {
    useAlert(error?.response?.data?.error || 'Failed to suggest keywords');
  } finally {
    isSuggesting.value = false;
  }
};

const applyTemplate = template => {
  state.title = template.title;
  state.description = template.description;
  state.instruction = template.instruction;
  state.trigger_keywords = template.trigger_keywords;
  showTemplateSelect.value = false;
};
</script>

<template>
  <!-- eslint-disable vue/no-bare-strings-in-template, @intlify/vue-i18n/no-raw-text, @intlify/vue-i18n/no-dynamic-keys -->
  <div
    v-on-click-outside="() => togglePopover(false)"
    class="inline-flex relative"
  >
    <Button
      :label="t(props.triggerLabel)"
      :icon="props.triggerIcon"
      :faded="props.triggerFaded"
      sm
      slate
      class="flex-shrink-0"
      @click="togglePopover(!showPopover)"
    />

    <div
      v-if="showPopover"
      class="w-[31.25rem] absolute top-10 ltr:left-0 rtl:right-0 bg-n-alpha-3 backdrop-blur-[100px] p-6 rounded-xl border border-n-weak shadow-md flex flex-col gap-6 z-50"
    >
      <h3 class="text-base font-medium text-n-slate-12">
        {{ t(`CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.TITLE`) }}
      </h3>

      <!-- Template Selector -->
      <div v-if="!showTemplateSelect" class="flex justify-start">
        <Button
          :label="t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.LOAD_TEMPLATE')"
          icon="i-lucide-layout-template"
          slate
          faded
          xs
          @click="showTemplateSelect = true"
        />
      </div>
      <div v-else class="p-3 bg-n-alpha-2 rounded-lg border border-n-weak">
        <div class="flex items-center justify-between mb-2">
          <span class="text-xs font-semibold text-n-slate-11">
            {{
              t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.TEMPLATE_SELECT_LABEL')
            }}
          </span>
          <Button
            icon="i-lucide-x"
            slate
            ghost
            xs
            @click="showTemplateSelect = false"
          />
        </div>
        <div class="space-y-2">
          <button
            v-for="tpl in SCENARIO_TEMPLATES"
            :key="tpl.id"
            class="w-full text-left p-2 rounded hover:bg-n-alpha-1 text-sm text-n-slate-12 border border-transparent hover:border-n-weak transition-all"
            @click="applyTemplate(tpl)"
          >
            <span class="font-medium block">{{ tpl.title }}</span>
            <span class="text-xs text-n-slate-11 line-clamp-1">
              {{ tpl.description }}
            </span>
          </button>
        </div>
      </div>

      <div class="max-h-[31.25rem] overflow-y-auto flex flex-col gap-4">
        <Input
          v-model="state.title"
          :label="t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.TITLE.LABEL')"
          :placeholder="
            t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.TITLE.PLACEHOLDER')
          "
          :message="titleError"
          :message-type="titleError ? 'error' : 'info'"
        />

        <TextArea
          v-model="state.description"
          :label="
            t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.DESCRIPTION.LABEL')
          "
          :placeholder="
            t(
              'CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.DESCRIPTION.PLACEHOLDER'
            )
          "
          :message="descriptionError"
          :message-type="descriptionError ? 'error' : 'info'"
          show-character-count
        />
        <Editor
          v-model="state.instruction"
          :label="
            t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.INSTRUCTION.LABEL')
          "
          :placeholder="
            t(
              'CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.INSTRUCTION.PLACEHOLDER'
            )
          "
          :message="instructionError"
          :message-type="instructionError ? 'error' : 'info'"
          :show-character-count="false"
          enable-captain-tools
        />

        <div class="flex flex-col gap-2">
          <div class="flex items-center justify-between">
            <label class="text-xs font-medium text-n-slate-11">
              {{
                t(
                  'CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.TRIGGER_KEYWORDS.LABEL'
                )
              }}
            </label>
            <Button
              :label="
                t(
                  'CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.TRIGGER_KEYWORDS.SUGGEST_BUTTON'
                )
              "
              icon="i-lucide-sparkles"
              xs
              ghost
              slate
              :is-loading="isSuggesting"
              @click="onSuggestTriggers"
            />
          </div>
          <TextArea
            v-model="state.trigger_keywords"
            :placeholder="
              t(
                'CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.TRIGGER_KEYWORDS.PLACEHOLDER'
              )
            "
            min-height="80px"
          />
        </div>

        <div class="flex flex-col gap-2">
          <label class="text-xs font-medium text-n-slate-11">
            {{ t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.TOOLS.LABEL') }}
          </label>
          <TagMultiSelectComboBox
            v-model="state.tools"
            :options="toolOptions"
            :placeholder="
              t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.TOOLS.PLACEHOLDER')
            "
          />
        </div>
      </div>

      <div class="flex items-center justify-between w-full gap-3">
        <Button
          variant="faded"
          color="slate"
          :label="t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.CANCEL')"
          class="w-full bg-n-alpha-2 !text-n-blue-text hover:bg-n-alpha-3"
          @click="onClickCancel"
        />
        <Button
          :label="t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.CREATE')"
          class="w-full"
          @click="onClickAdd"
        />
      </div>
    </div>
  </div>
</template>
