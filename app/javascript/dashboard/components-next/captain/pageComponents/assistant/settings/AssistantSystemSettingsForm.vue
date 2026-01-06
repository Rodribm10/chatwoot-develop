<script setup>
import { reactive, computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { minLength } from '@vuelidate/validators';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { useAccount } from 'dashboard/composables/useAccount';

import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Draggable from 'vuedraggable';

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
const systemPromptBlocks = ref([]);
const activeBlockIndex = ref(null);
const activeBlockDraft = reactive({ title: '', content: '' });
const blockEditorDialog = ref(null);
const promptPreviewDialog = ref(null);

const systemPromptVersions = computed(
  () => props.assistant?.config?.system_prompt_versions || []
);
const hasSystemPromptVersions = computed(
  () => systemPromptVersions.value.length > 0
);

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

const normalizeBlocks = blocks =>
  blocks.map((block, index) => ({
    uid: block.uid || `${Date.now()}-${index}`,
    key: block.key || null,
    title: block.title || '',
    content: block.content || '',
    order: block.order ?? index,
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
  const blocks =
    config.system_prompt_blocks || assistant.system_prompt_blocks_preview || [];
  systemPromptBlocks.value = normalizeBlocks(blocks);
};

const sanitizedBlocks = computed(() =>
  systemPromptBlocks.value.map((block, index) => ({
    key: block.key || null,
    title: block.title,
    content: block.content,
    order: index,
  }))
);

const fullPrompt = computed(() =>
  systemPromptBlocks.value
    .map(block => {
      const title = block.title?.trim();
      const content = block.content?.trim();
      if (!title && !content) return null;
      return `[${title}]\n${content}`;
    })
    .filter(Boolean)
    .join('\n\n')
);

const promptCharLimit = computed(() => {
  const provider = props.assistant?.llm_provider || '';
  const model = props.assistant?.llm_model || '';
  const isGemini =
    provider.toLowerCase().includes('gemini') ||
    model.toLowerCase().includes('gemini');
  return isGemini ? 80000 : 40000;
});

const isPromptOverLimit = computed(
  () => fullPrompt.value.length > promptCharLimit.value
);

const activeBlockTitle = computed({
  get() {
    return activeBlockDraft.title;
  },
  set(value) {
    activeBlockDraft.title = value;
  },
});

const activeBlockContent = computed({
  get() {
    return activeBlockDraft.content;
  },
  set(value) {
    activeBlockDraft.content = value;
  },
});

const playbookFromBlocks = computed(() => {
  const block = systemPromptBlocks.value.find(b => b.key === 'playbook');
  return block?.content || '';
});

const buildPayload = (extra = {}) => {
  const config = {
    ...props.assistant.config,
    handoff_message: state.handoffMessage,
    resolution_message: state.resolutionMessage,
    temperature: state.temperature !== undefined ? state.temperature : 1,
    playbook: state.playbook,
    distance_threshold: state.distanceThreshold,
    max_rag_results: state.maxRagResults,
  };

  if (isCaptainV2Enabled.value) {
    config.system_prompt_blocks = sanitizedBlocks.value;
    config.playbook = playbookFromBlocks.value || state.playbook;
  }

  return {
    config,
    ...extra,
  };
};

const handleSystemMessagesUpdate = async () => {
  if (isCaptainV2Enabled.value && isPromptOverLimit.value) {
    return;
  }
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

  const payload = buildPayload();

  if (!isCaptainV2Enabled.value) {
    payload.config.instructions = state.instructions;
  }

  emit('submit', payload);
};

const handleSaveSystemPromptVersion = () => {
  if (isPromptOverLimit.value) return;
  const payload = buildPayload({ system_prompt_action: 'save_version' });
  emit('submit', payload);
};

const handleRevertSystemPromptVersion = () => {
  const payload = buildPayload({ system_prompt_action: 'revert_last' });
  emit('submit', payload);
};

const handleRestoreSystemPromptDefault = () => {
  const payload = buildPayload({ system_prompt_action: 'restore_default' });
  emit('submit', payload);
};

const handleAddBlock = () => {
  systemPromptBlocks.value.push({
    uid: `${Date.now()}-${systemPromptBlocks.value.length}`,
    key: null,
    title: '',
    content: '',
    order: systemPromptBlocks.value.length,
  });
};

const handleRemoveBlock = index => {
  systemPromptBlocks.value.splice(index, 1);
};

const handleEditBlock = index => {
  activeBlockIndex.value = index;
  const block = systemPromptBlocks.value[index];
  activeBlockDraft.title = block?.title || '';
  activeBlockDraft.content = block?.content || '';
  blockEditorDialog.value?.open();
};

const handleBlockModalClosed = () => {
  activeBlockIndex.value = null;
};

const handleCancelBlockModal = () => {
  blockEditorDialog.value?.close();
};

const handleApplyBlockChanges = () => {
  const block = systemPromptBlocks.value[activeBlockIndex.value];
  if (block) {
    block.title = activeBlockDraft.title;
    block.content = activeBlockDraft.content;
  }
  handleCancelBlockModal();
};

const handleOpenPromptPreview = () => {
  promptPreviewDialog.value?.open();
};

const handleClosePromptPreview = () => {
  promptPreviewDialog.value?.close();
};

const handlePromptPreviewClosed = () => {};

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

    <div v-if="isCaptainV2Enabled" class="flex flex-col gap-4">
      <div class="flex items-center justify-between gap-4">
        <label class="text-sm font-medium text-n-slate-12">
          {{ t('CAPTAIN.ASSISTANTS.FORM.SYSTEM_PROMPT_BLOCKS.LABEL') }}
        </label>
        <div class="flex flex-wrap gap-2">
          <Button
            :label="t('CAPTAIN.ASSISTANTS.FORM.SYSTEM_PROMPT.SAVE_VERSION')"
            variant="faded"
            color="slate"
            @click="handleSaveSystemPromptVersion"
          />
          <Button
            :label="t('CAPTAIN.ASSISTANTS.FORM.SYSTEM_PROMPT.REVERT_LAST')"
            variant="faded"
            color="slate"
            :disabled="!hasSystemPromptVersions"
            @click="handleRevertSystemPromptVersion"
          />
          <Button
            :label="t('CAPTAIN.ASSISTANTS.FORM.SYSTEM_PROMPT.RESTORE_DEFAULT')"
            variant="faded"
            color="slate"
            @click="handleRestoreSystemPromptDefault"
          />
        </div>
      </div>
      <div class="flex items-center justify-between text-xs text-n-slate-11">
        <span>
          {{
            t('CAPTAIN.ASSISTANTS.FORM.SYSTEM_PROMPT_BLOCKS.CHAR_COUNT', {
              count: fullPrompt.length,
              limit: promptCharLimit,
            })
          }}
        </span>
        <Button
          :label="t('CAPTAIN.ASSISTANTS.FORM.SYSTEM_PROMPT_BLOCKS.VIEW_FULL')"
          variant="faded"
          color="slate"
          @click="handleOpenPromptPreview"
        />
      </div>
      <p v-if="isPromptOverLimit" class="text-xs text-ruby-9">
        {{ t('CAPTAIN.ASSISTANTS.FORM.SYSTEM_PROMPT_BLOCKS.LIMIT_WARNING') }}
      </p>
      <Draggable
        v-model="systemPromptBlocks"
        item-key="uid"
        handle=".drag-handle"
        class="flex flex-col gap-3"
      >
        <template #item="{ element, index }">
          <div class="rounded-lg border border-n-weak p-4 flex flex-col gap-3">
            <div class="flex items-center gap-2">
              <span class="drag-handle cursor-grab text-n-slate-11">
                <i class="i-lucide-grip-vertical" aria-hidden="true" />
              </span>
              <Input
                v-model="element.title"
                :placeholder="
                  t(
                    'CAPTAIN.ASSISTANTS.FORM.SYSTEM_PROMPT_BLOCKS.TITLE_PLACEHOLDER'
                  )
                "
              />
            </div>
            <div
              class="flex items-center justify-between gap-3 text-xs text-n-slate-11"
            >
              <span class="truncate">
                {{
                  element.content?.slice(0, 120) ||
                  t(
                    'CAPTAIN.ASSISTANTS.FORM.SYSTEM_PROMPT_BLOCKS.EMPTY_CONTENT'
                  )
                }}
              </span>
              <div class="flex gap-2">
                <Button
                  :label="
                    t('CAPTAIN.ASSISTANTS.FORM.SYSTEM_PROMPT_BLOCKS.EDIT')
                  "
                  variant="faded"
                  color="slate"
                  @click="handleEditBlock(index)"
                />
                <Button
                  v-if="!element.key"
                  :label="
                    t('CAPTAIN.ASSISTANTS.FORM.SYSTEM_PROMPT_BLOCKS.REMOVE')
                  "
                  variant="faded"
                  color="ruby"
                  @click="handleRemoveBlock(index)"
                />
              </div>
            </div>
          </div>
        </template>
      </Draggable>
      <Button
        :label="t('CAPTAIN.ASSISTANTS.FORM.SYSTEM_PROMPT_BLOCKS.ADD')"
        variant="faded"
        color="slate"
        class="w-fit"
        @click="handleAddBlock"
      />
    </div>

    <Editor
      v-if="!isCaptainV2Enabled"
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
        :disabled="isCaptainV2Enabled && isPromptOverLimit"
        @click="handleSystemMessagesUpdate"
      />
    </div>

    <Dialog
      ref="blockEditorDialog"
      :title="t('CAPTAIN.ASSISTANTS.FORM.SYSTEM_PROMPT_BLOCKS.EDIT_TITLE')"
      width="3xl"
      overflow-y-auto
      :show-confirm-button="false"
      @close="handleBlockModalClosed"
    >
      <div class="flex flex-col gap-4 min-h-[75vh]">
        <Input
          v-model="activeBlockTitle"
          :label="t('CAPTAIN.ASSISTANTS.FORM.SYSTEM_PROMPT_BLOCKS.TITLE_LABEL')"
          :placeholder="
            t('CAPTAIN.ASSISTANTS.FORM.SYSTEM_PROMPT_BLOCKS.TITLE_PLACEHOLDER')
          "
        />
        <div class="system-prompt-block-editor">
          <Editor
            v-model="activeBlockContent"
            :label="
              t('CAPTAIN.ASSISTANTS.FORM.SYSTEM_PROMPT_BLOCKS.CONTENT_LABEL')
            "
            :placeholder="
              t(
                'CAPTAIN.ASSISTANTS.FORM.SYSTEM_PROMPT_BLOCKS.CONTENT_PLACEHOLDER'
              )
            "
            :max-length="promptCharLimit"
            class="z-0 h-[70vh]"
          />
        </div>
      </div>
      <template #footer>
        <div class="flex items-center justify-end w-full gap-2">
          <Button
            :label="t('CAPTAIN.ASSISTANTS.FORM.SYSTEM_PROMPT_BLOCKS.CANCEL')"
            variant="faded"
            color="slate"
            type="button"
            @click.stop="handleCancelBlockModal"
          />
          <Button
            :label="t('CAPTAIN.ASSISTANTS.FORM.SYSTEM_PROMPT_BLOCKS.DONE')"
            type="button"
            @click.stop="handleApplyBlockChanges"
          />
        </div>
      </template>
    </Dialog>

    <Dialog
      ref="promptPreviewDialog"
      :title="t('CAPTAIN.ASSISTANTS.FORM.SYSTEM_PROMPT_BLOCKS.PREVIEW_TITLE')"
      width="3xl"
      :show-confirm-button="false"
      @close="handlePromptPreviewClosed"
    >
      <pre
        class="text-xs text-n-slate-11 whitespace-pre-wrap max-h-[60vh] overflow-y-auto"
      >
        {{ fullPrompt }}
      </pre>
      <template #footer>
        <div class="flex items-center justify-end w-full">
          <Button
            :label="t('CAPTAIN.ASSISTANTS.FORM.SYSTEM_PROMPT_BLOCKS.CLOSE')"
            type="button"
            @click="handleClosePromptPreview"
          />
        </div>
      </template>
    </Dialog>
  </div>
</template>

<style scoped>
.system-prompt-block-editor :deep(.ProseMirror-woot-style) {
  min-height: 60vh;
  max-height: 60vh;
}
</style>
