<script setup>
import { reactive, computed, ref, nextTick, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, requiredIf } from '@vuelidate/validators';
import { useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';

import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  mode: {
    type: String,
    default: 'create',
    validator: value => ['create', 'edit'].includes(value),
  },
  asset: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['submit', 'cancel']);

const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB
const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];

const { t } = useI18n();

const formState = {
  uiFlags: useMapGetter('captainAssets/getUIFlags'),
};

const initialState = {
  name: '',
  file: null,
};

const state = reactive({ ...initialState });
const fileInputRef = ref(null);
const isEditMode = computed(() => props.mode === 'edit');

const validationRules = {
  name: { required },
  file: { required: requiredIf(() => !isEditMode.value) },
};

const v$ = useVuelidate(validationRules, state);

const isLoading = computed(() =>
  isEditMode.value
    ? formState.uiFlags.value.updatingItem
    : formState.uiFlags.value.creatingItem
);

const getErrorMessage = field => {
  return v$.value[field].$error
    ? t(`CAPTAIN.ASSETS.FORM.${field.toUpperCase()}.ERROR`)
    : '';
};

const formErrors = computed(() => ({
  name: getErrorMessage('name'),
  file: getErrorMessage('file'),
}));

const handleCancel = () => emit('cancel');

const openFileDialog = () => {
  nextTick(() => {
    fileInputRef.value?.click();
  });
};

const handleFileChange = event => {
  const file = event.target.files[0];
  if (!file) return;

  if (!ALLOWED_TYPES.includes(file.type)) {
    useAlert(t('CAPTAIN.ASSETS.FORM.FILE.INVALID_TYPE'));
    event.target.value = '';
    return;
  }

  if (file.size > MAX_FILE_SIZE) {
    useAlert(t('CAPTAIN.ASSETS.FORM.FILE.TOO_LARGE'));
    event.target.value = '';
    return;
  }

  state.file = file;
  if (!state.name) {
    state.name = file.name.replace(/\.[^/.]+$/, '');
  }
};

const updateStateFromAsset = asset => {
  state.name = asset?.name || '';
  state.file = null;
};

const prepareAssetDetails = () => {
  const formData = new FormData();
  formData.append('asset[name]', state.name);
  if (state.file) {
    formData.append('asset[file]', state.file);
  }
  return formData;
};

const handleSubmit = async () => {
  const isFormValid = await v$.value.$validate();
  if (!isFormValid) return;

  emit('submit', prepareAssetDetails());
};

watch(
  () => props.asset,
  asset => {
    if (isEditMode.value && asset) {
      updateStateFromAsset(asset);
    }
  },
  { immediate: true }
);
</script>

<template>
  <!-- eslint-disable vue/no-bare-strings-in-template -->
  <form class="flex flex-col gap-4" @submit.prevent="handleSubmit">
    <Input
      v-model="state.name"
      :label="t('CAPTAIN.ASSETS.FORM.NAME.LABEL')"
      :placeholder="t('CAPTAIN.ASSETS.FORM.NAME.PLACEHOLDER')"
      :message="formErrors.name"
      :message-type="formErrors.name ? 'error' : 'info'"
    />

    <div class="flex flex-col gap-2">
      <label class="text-sm font-medium text-n-slate-12">
        {{ t('CAPTAIN.ASSETS.FORM.FILE.LABEL') }}
      </label>
      <input
        ref="fileInputRef"
        type="file"
        accept="image/*"
        class="hidden"
        @change="handleFileChange"
      />
      <Button
        type="button"
        :color="formErrors.file ? 'ruby' : 'slate'"
        :variant="formErrors.file ? 'outline' : 'solid'"
        class="!w-full !h-auto !justify-between !py-4"
        :is-loading="isLoading"
        @click="openFileDialog"
      >
        <template #default>
          <div class="flex gap-2 items-center">
            <div
              class="flex justify-center items-center w-10 h-10 rounded-lg bg-n-slate-3"
            >
              <i class="text-xl i-ph-image text-n-slate-11" />
            </div>
            <div class="flex flex-col flex-1 gap-1 items-start">
              <p class="m-0 text-sm font-medium text-n-slate-12">
                {{
                  state.file
                    ? state.file.name
                    : t('CAPTAIN.ASSETS.FORM.FILE.CHOOSE_FILE')
                }}
              </p>
              <p class="m-0 text-xs text-n-slate-11">
                {{
                  state.file
                    ? `${(state.file.size / 1024 / 1024).toFixed(2)} MB`
                    : t('CAPTAIN.ASSETS.FORM.FILE.HELP_TEXT')
                }}
              </p>
            </div>
          </div>
        </template>
      </Button>
      <span v-if="formErrors.file" class="text-xs text-n-ruby-11">
        {{ formErrors.file }}
      </span>
    </div>

    <div class="flex gap-2 justify-end">
      <Button
        variant="faded"
        color="slate"
        :label="t('CAPTAIN.FORM.CANCEL')"
        @click="handleCancel"
      />
      <Button
        :label="t(isEditMode ? 'CAPTAIN.FORM.EDIT' : 'CAPTAIN.FORM.CREATE')"
        @click="handleSubmit"
      />
    </div>
  </form>
</template>
