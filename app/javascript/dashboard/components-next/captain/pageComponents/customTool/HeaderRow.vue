<script setup>
import { computed, defineModel, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';

const emit = defineEmits(['remove']);
const { t } = useI18n();
const showErrors = ref(false);

const headerKey = defineModel('headerKey', {
  type: String,
  required: true,
});

const headerValue = defineModel('headerValue', {
  type: String,
  required: true,
});

const validationError = computed(() => {
  if (!headerKey.value || headerKey.value.trim() === '') {
    return 'HEADER_KEY_REQUIRED';
  }
  if (!headerValue.value || headerValue.value.trim() === '') {
    return 'HEADER_VALUE_REQUIRED';
  }
  return null;
});

watch([headerKey, headerValue], () => {
  showErrors.value = false;
});

const validate = () => {
  showErrors.value = true;
  return !validationError.value;
};

defineExpose({ validate });
</script>

<template>
  <!-- eslint-disable vue/no-bare-strings-in-template -->
  <li class="list-none">
    <div
      class="flex items-start gap-2 p-3 rounded-lg border border-n-weak bg-n-alpha-2"
      :class="{
        'animate-wiggle border-n-ruby-9': showErrors && validationError,
      }"
    >
      <div class="flex flex-col flex-1 gap-3">
        <div class="grid grid-cols-2 gap-2">
          <Input
            v-model="headerKey"
            :placeholder="t('CAPTAIN.CUSTOM_TOOLS.FORM.HEADER_KEY.PLACEHOLDER')"
          />
          <Input
            v-model="headerValue"
            :placeholder="
              t('CAPTAIN.CUSTOM_TOOLS.FORM.HEADER_VALUE.PLACEHOLDER')
            "
          />
        </div>
      </div>
      <Button
        solid
        slate
        icon="i-lucide-trash"
        class="flex-shrink-0"
        @click.stop="emit('remove')"
      />
    </div>
    <span
      v-if="showErrors && validationError"
      class="block mt-1 text-sm text-n-ruby-11"
    >
      {{ t(`CAPTAIN.CUSTOM_TOOLS.FORM.ERRORS.${validationError}`) }}
    </span>
  </li>
</template>
