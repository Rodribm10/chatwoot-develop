<script setup>
import { computed } from 'vue';

import { useStoreGetters } from 'dashboard/composables/store';

import SettingsLayout from 'dashboard/routes/dashboard/settings/SettingsLayout.vue';
import BaseSettingsHeader from 'dashboard/routes/dashboard/settings/components/BaseSettingsHeader.vue';
import JasmineToolsTab from 'dashboard/routes/dashboard/jasmine/components/JasmineToolsTab.vue';

const getters = useStoreGetters();

// Get all inboxes for the account
const allInboxes = computed(() => getters['inboxes/getInboxes'].value || []);

// Use the first available inbox ID (since tools are account-wide, not inbox-specific)
const inboxId = computed(() => {
  if (allInboxes.value.length > 0) {
    return allInboxes.value[0].id;
  }
  return null;
});
</script>

<template>
  <!-- eslint-disable vue/no-bare-strings-in-template -->
  <SettingsLayout :is-loading="false">
    <template #header>
      <BaseSettingsHeader
        title="Ferramentas Integradas"
        description="Configure as credenciais (ID e Token) para as ferramentas que o Capitão pode utilizar durante os atendimentos."
      />
    </template>

    <template #body>
      <div v-if="!inboxId" class="text-center py-12 text-n-slate-11">
        <p>
          Nenhuma caixa de entrada disponível. Crie uma caixa para configurar
          ferramentas.
        </p>
      </div>
      <JasmineToolsTab v-else :inbox-id="inboxId" />
    </template>
  </SettingsLayout>
</template>
