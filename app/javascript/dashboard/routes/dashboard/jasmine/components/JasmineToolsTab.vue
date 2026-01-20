<script setup>
import { ref, onMounted } from 'vue';
import { useAlert } from 'dashboard/composables';
import JasmineAPI from 'dashboard/api/inbox/jasmine';
import JasmineToolCard from './JasmineToolCard.vue';
// Removing Spinner import to test
// import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  inboxId: { type: [String, Number], required: true },
});

const tools = ref([]);
const isLoading = ref(true);
// const { showAlert } = useAlert(); <-- Wrong usage

async function fetchTools() {
  if (tools.value.length === 0) isLoading.value = true;

  try {
    const { data } = await JasmineAPI.getTools(props.inboxId);
    // console.log('[JasmineTools] Loaded:', data);
    tools.value = data || [];
  } catch (error) {
    // console.error('[JasmineTools] Error:', error);
    useAlert('Erro ao carregar ferramentas');
  } finally {
    isLoading.value = false;
  }
}

function handleUpdate() {
  // [INTENTIONAL] updatedToolData reserved for future optimistic updates.
  fetchTools();
}

onMounted(() => {
  fetchTools();
});
</script>

<template>
  <!-- eslint-disable vue/no-bare-strings-in-template -->
  <!-- eslint-disable @intlify/vue-i18n/no-raw-text -->
  <div class="mx-auto max-w-screen-md px-5 py-8 font-inter">
    <div class="flex flex-col gap-6">
      <div class="mb-2">
        <h2 class="text-2xl font-medium text-n-slate-12 mb-2">
          Ferramentas Integradas
        </h2>
        <p class="text-sm text-n-slate-11">
          Configure as credenciais (ID e Token) para as ferramentas que o
          Jasmine pode utilizar durante os atendimentos.
        </p>
      </div>

      <div v-if="isLoading" class="flex justify-center py-12">
        <span class="text-n-slate-11">Carregando ferramentas...</span>
      </div>

      <div
        v-else-if="tools.length === 0"
        class="text-center py-12 bg-n-alpha-1 rounded-lg border border-n-weak"
      >
        <p class="text-n-slate-11">Nenhuma ferramenta disponível no sistema.</p>
      </div>

      <div v-else class="space-y-6">
        <JasmineToolCard
          v-for="tool in tools && tools.length ? tools : []"
          :key="tool.key"
          :tool="tool"
          :inbox-id="inboxId"
          @update="handleUpdate"
        />
      </div>
    </div>
  </div>
</template>
