<script setup>
import { onMounted, ref } from 'vue';
import { useAlert } from 'dashboard/composables';
import { useRoute } from 'vue-router';
import SettingsLayout from '../../settings/SettingsLayout.vue';
import BaseSettingsHeader from '../../settings/components/BaseSettingsHeader.vue';

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
    useAlert('Configuracoes salvas com sucesso.');
  } catch (error) {
    useAlert('Nao foi possivel salvar as configuracoes.');
  } finally {
    isSaving.value = false;
  }
};

onMounted(fetchConfig);
</script>

<template>
  <SettingsLayout>
    <!-- eslint-disable vue/no-bare-strings-in-template, @intlify/vue-i18n/no-raw-text -->
    <BaseSettingsHeader
      title="Configuracoes do Captain"
      description="Defina os textos e cores exibidos no Captain."
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
            Titulo da pagina
          </label>
          <input
            v-model="formData.title"
            type="text"
            class="w-full px-3 py-2 border rounded-md dark:bg-slate-900 border-slate-200 dark:border-slate-700"
            placeholder="Ex: Atendimento Captain"
          />
        </div>

        <div>
          <label
            class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1"
          >
            Subtitulo
          </label>
          <input
            v-model="formData.subtitle"
            type="text"
            class="w-full px-3 py-2 border rounded-md dark:bg-slate-900 border-slate-200 dark:border-slate-700"
            placeholder="Ex: Como podemos ajudar?"
          />
        </div>

        <div>
          <label
            class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1"
          >
            Telefone
          </label>
          <input
            v-model="formData.phone_number"
            type="text"
            class="w-full px-3 py-2 border rounded-md dark:bg-slate-900 border-slate-200 dark:border-slate-700"
            placeholder="Ex: +55 (11) 99999-0000"
          />
        </div>

        <div>
          <label
            class="block text-sm font-medium text-slate-700 dark:text-slate-200 mb-1"
          >
            Cor primaria
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
            Salvar configuracoes
          </woot-button>
        </div>
      </div>
    </div>
  </SettingsLayout>
</template>
