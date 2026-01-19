<script setup>
import { onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useRoute } from 'vue-router';
import SettingsLayout from '../../settings/SettingsLayout.vue';
import BaseSettingsHeader from '../../settings/components/BaseSettingsHeader.vue';

const { t } = useI18n();
const isLoading = ref(false);
const isSaving = ref(false);
const route = useRoute();
const accountId = route.params.accountId;

const formData = ref({
  title: '',
  subtitle: '',
  primary_color: '#00af9e',
  phone_number: '',
});

const fetchConfig = async () => {
  isLoading.value = true;
  try {
    const { data } = await window.axios.get(
      `/api/v1/accounts/${accountId}/captain/configuration`
    );
    formData.value = {
      title: data.title || '',
      subtitle: data.subtitle || '',
      primary_color: data.primary_color || '#00af9e',
      phone_number: data.phone_number || '',
    };
  } catch (error) {
    // Ignore 404 if not set yet
  } finally {
    isLoading.value = false;
  }
};

const saveConfig = async () => {
  isSaving.value = true;
  try {
    await window.axios.put(
      `/api/v1/accounts/${accountId}/captain/configuration`,
      { configuration: formData.value }
    );
    useAlert(t('CAPTAIN.CONFIGURATIONS.SUCCESS'));
  } catch (error) {
    useAlert(t('CAPTAIN.CONFIGURATIONS.ERROR'));
  } finally {
    isSaving.value = false;
  }
};

onMounted(fetchConfig);
</script>

<template>
  <SettingsLayout>
    <BaseSettingsHeader
      :title="t('CAPTAIN.CONFIGURATIONS.TITLE')"
      :description="t('CAPTAIN.CONFIGURATIONS.DESCRIPTION')"
    />

    <div class="flex flex-col gap-4 p-8 max-w-2xl">
      <div v-if="isLoading" class="text-center">
        <span class="spinner" />
      </div>

      <div
        v-else
        class="flex flex-col gap-6 p-6 bg-white dark:bg-slate-900 rounded-md border border-slate-100 dark:border-slate-800"
      >
        <div>
          <label
            class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1"
          >
            {{ t('CAPTAIN.CONFIGURATIONS.FORM.PAGE_TITLE_LABEL') }}
          </label>
          <input
            v-model="formData.title"
            type="text"
            class="w-full px-3 py-2 border rounded-md dark:bg-slate-900 border-slate-200 dark:border-slate-700"
            :placeholder="
              t('CAPTAIN.CONFIGURATIONS.FORM.PAGE_TITLE_PLACEHOLDER')
            "
          />
        </div>

        <div>
          <label
            class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1"
          >
            {{ t('CAPTAIN.CONFIGURATIONS.FORM.SUBTITLE_LABEL') }}
          </label>
          <input
            v-model="formData.subtitle"
            type="text"
            class="w-full px-3 py-2 border rounded-md dark:bg-slate-900 border-slate-200 dark:border-slate-700"
            :placeholder="t('CAPTAIN.CONFIGURATIONS.FORM.SUBTITLE_PLACEHOLDER')"
          />
        </div>

        <div>
          <label
            class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1"
          >
            {{ t('CAPTAIN.CONFIGURATIONS.FORM.PHONE_LABEL') }}
          </label>
          <input
            v-model="formData.phone_number"
            type="text"
            class="w-full px-3 py-2 border rounded-md dark:bg-slate-900 border-slate-200 dark:border-slate-700"
            :placeholder="t('CAPTAIN.CONFIGURATIONS.FORM.PHONE_PLACEHOLDER')"
          />
        </div>

        <div>
          <label
            class="block text-sm font-medium text-slate-700 dark:text-slate-200 mb-1"
          >
            {{ t('CAPTAIN.CONFIGURATIONS.FORM.PRIMARY_COLOR_LABEL') }}
          </label>
          <div class="flex gap-2 items-center">
            <input
              v-model="formData.primary_color"
              type="color"
              class="h-10 w-20 p-1 border rounded-md"
            />
            <input
              v-model="formData.primary_color"
              type="text"
              class="px-3 py-2 border rounded-md dark:bg-slate-900 border-slate-200 dark:border-slate-700"
            />
          </div>
        </div>

        <div class="pt-4 border-t dark:border-slate-800">
          <woot-button :is-loading="isSaving" @click="saveConfig">
            {{ t('CAPTAIN.CONFIGURATIONS.FORM.SUBMIT') }}
          </woot-button>
        </div>
      </div>
    </div>
  </SettingsLayout>
</template>
