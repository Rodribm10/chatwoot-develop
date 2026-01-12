<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { copyTextToClipboard } from 'shared/helpers/clipboard';

import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  id: {
    type: Number,
    required: true,
  },
  name: {
    type: String,
    required: true,
  },
  fileUrl: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['action']);
const { t } = useI18n();

const shortcut = computed(() => `{{ media.${props.name} }}`);

const copyShortcut = async () => {
  await copyTextToClipboard(shortcut.value);
  useAlert(t('CAPTAIN.ASSETS.COPY_SHORTCUT.SUCCESS'));
};

const copyUrl = async () => {
  if (!props.fileUrl) return;
  await copyTextToClipboard(props.fileUrl);
  useAlert(t('CAPTAIN.ASSETS.COPY_URL.SUCCESS'));
};

const handleDelete = () => {
  emit('action', { action: 'delete', id: props.id });
};

const handleEdit = () => {
  emit('action', { action: 'edit', id: props.id });
};
</script>

<template>
  <!-- eslint-disable vue/no-bare-strings-in-template -->
  <div class="flex gap-4 p-4 border border-n-weak rounded-md bg-n-alpha-2">
    <div class="w-20 h-20 rounded-md overflow-hidden bg-n-slate-3">
      <img
        v-if="fileUrl"
        :src="fileUrl"
        :alt="name"
        class="w-full h-full object-cover"
      />
      <div v-else class="w-full h-full flex items-center justify-center">
        <i class="text-2xl i-ph-image text-n-slate-11" />
      </div>
    </div>

    <div class="flex-1 flex flex-col gap-2">
      <div class="flex items-center justify-between gap-4">
        <div>
          <h4 class="text-base font-semibold text-n-slate-12">
            {{ name }}
          </h4>
          <p class="text-xs text-n-slate-11">
            {{ t('CAPTAIN.ASSETS.SHORTCUT_LABEL') }}:
            <span class="font-mono">{{ shortcut }}</span>
          </p>
        </div>
        <div class="flex gap-1">
          <Button
            icon="i-lucide-pencil"
            variant="ghost"
            color="slate"
            @click="handleEdit"
          />
          <Button
            icon="i-lucide-trash"
            variant="ghost"
            color="slate"
            @click="handleDelete"
          />
        </div>
      </div>
      <div class="flex flex-wrap gap-2">
        <Button
          sm
          icon="i-lucide-copy"
          variant="ghost"
          color="slate"
          :label="t('CAPTAIN.ASSETS.COPY_SHORTCUT.LABEL')"
          @click="copyShortcut"
        />
        <Button
          v-if="fileUrl"
          sm
          icon="i-lucide-link"
          variant="ghost"
          color="slate"
          :label="t('CAPTAIN.ASSETS.COPY_URL.LABEL')"
          @click="copyUrl"
        />
      </div>
    </div>
  </div>
</template>
