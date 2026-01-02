<script setup>
import { ref, watch, computed } from 'vue';
import JasmineAPI from 'dashboard/api/inbox/jasmine';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import WootSwitch from 'dashboard/components-next/switch/Switch.vue';

const props = defineProps({
  tool: { type: Object, required: true },
  inboxId: { type: [String, Number], required: true },
});

const emit = defineEmits(['update']);
// const { showAlert } = useAlert();

// Local copy of state
const isEnabled = ref(props.tool.is_enabled);
const config = ref({
  plug_play_id: props.tool.plug_play_id || '',
  plug_play_token: props.tool.plug_play_token || '',
});

const showToken = ref(false);
const isSaving = ref(false);
const isTesting = ref(false);
const testResult = ref(null);
const hasChanges = ref(false);

// Watch for changes to enable "Save" button
watch(
  config,
  () => {
    hasChanges.value = true;
  },
  { deep: true }
);
watch(isEnabled, newVal => {
  // If user toggles switch, we consider it a change that needs saving
  // Or we can auto-save. The requirement says "Toggle Ativar/Desativar"
  // Let's rely on the user clicking save for config, but maybe auto-save toggle?
  // Let's keep it manual save for consistency with the rest of the form
  hasChanges.value = true;
});

const statusColor = computed(() => {
  if (!props.tool.last_test) return 'text-n-slate-10';
  const status = props.tool.last_test.status;
  return status >= 200 && status < 300 ? 'text-green-600' : 'text-red-500';
});

async function saveConfig() {
  isSaving.value = true;
  try {
    const payload = {
      is_enabled: isEnabled.value,
      plug_play_id: config.value.plug_play_id,
      plug_play_token: config.value.plug_play_token,
    };

    const { data } = await JasmineAPI.updateTool(
      props.inboxId,
      props.tool.key,
      payload
    );

    // Update local state is handled by parent update usually, but let's sync
    config.value.plug_play_id = data.plug_play_id;
    config.value.plug_play_token = data.plug_play_token;
    hasChanges.value = false;

    useAlert('Configuração da ferramenta salva!');
    emit('update', data); // Let parent update the list if needed
  } catch (error) {
    useAlert(error?.response?.data?.error || error.message, 'error');
  } finally {
    isSaving.value = false;
  }
}

async function testConnection() {
  isTesting.value = true;
  testResult.value = null;
  try {
    const { data } = await JasmineAPI.testTool(props.inboxId, props.tool.key);
    testResult.value = data;
    // Emit update so parent can refresh last_test info
    if (data.success) {
      useAlert('Teste realizado com sucesso!');
    } else {
      useAlert('Teste falhou', 'error');
    }
    emit('update');
  } catch (error) {
    testResult.value = { success: false, error: error.message };
    useAlert('Erro ao testar conexão', 'error');
  } finally {
    isTesting.value = false;
  }
}

function formatDate(date) {
  if (!date) return '';
  return new Date(date).toLocaleString();
}

function formatJson(str) {
  try {
    if (typeof str === 'object') return JSON.stringify(str, null, 2);
    // Try to parse if it's a string, otherwise return as is
    const parsed = JSON.parse(str);
    return JSON.stringify(parsed, null, 2);
  } catch {
    return str;
  }
}
</script>

<template>
  <div class="bg-n-solid-1 border border-n-weak rounded-lg p-5 mb-4">
    <div class="flex justify-between items-start mb-4">
      <div>
        <div class="flex items-center gap-2 mb-1">
          <h4 class="text-base font-medium text-n-slate-12">
            {{ tool.name }}
          </h4>
          <span
            class="text-xs px-2 py-0.5 rounded bg-n-alpha-2 text-n-slate-11 font-mono uppercase border border-n-weak"
          >
            {{ tool.method }}
          </span>
        </div>
        <p class="text-sm text-n-slate-11 mb-2">{{ tool.description }}</p>
        <code
          class="text-xs text-n-slate-10 bg-n-alpha-1 px-2 py-1 rounded block truncate max-w-2xl font-mono border border-n-weak"
        >
          {{ tool.url }}
        </code>
      </div>

      <div class="flex items-center gap-2">
        <span
          class="text-sm font-medium"
          :class="isEnabled ? 'text-n-teal-11' : 'text-n-slate-10'"
        >
          {{ isEnabled ? 'Ativo' : 'Inativo' }}
        </span>
        <woot-switch v-model="isEnabled" />
      </div>
    </div>

    <!-- Edit Form -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
      <div>
        <label
          class="block text-xs font-medium text-n-slate-11 mb-1 uppercase tracking-wide"
          >PLUG-PLAY-ID</label
        >
        <input
          v-model="config.plug_play_id"
          type="text"
          class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-solid-2 text-n-slate-12 focus:border-n-brand focus:outline-none transition-colors text-sm"
          placeholder="ID do cliente"
        />
      </div>
      <div>
        <label
          class="block text-xs font-medium text-n-slate-11 mb-1 uppercase tracking-wide"
          >PLUG-PLAY-TOKEN</label
        >
        <div class="relative">
          <input
            v-model="config.plug_play_token"
            :type="showToken ? 'text' : 'password'"
            class="w-full px-3 py-2 rounded-lg border border-n-weak bg-n-solid-2 text-n-slate-12 focus:border-n-brand focus:outline-none transition-colors pr-10 text-sm"
            placeholder="Token de acesso"
          />
          <button
            class="absolute right-3 top-1/2 -translate-y-1/2 text-n-slate-10 hover:text-n-slate-12"
            @click="showToken = !showToken"
            tabindex="-1"
          >
            <i :class="showToken ? 'i-lucide-eye-off' : 'i-lucide-eye'" />
          </button>
        </div>
      </div>
    </div>

    <!-- Footer / Status -->
    <div
      class="flex flex-col md:flex-row justify-between items-center pt-4 border-t border-n-weak gap-4"
    >
      <div class="text-xs text-n-slate-10">
        <template v-if="tool.last_test">
          <div class="flex items-center gap-2">
            <span
              class="w-2 h-2 rounded-full"
              :class="statusColor.replace('text-', 'bg-')"
            ></span>
            <span>
              Status:
              <span class="font-mono font-medium" :class="statusColor">{{
                tool.last_test.status
              }}</span>
            </span>
            <span class="text-n-slate-9 mx-1">•</span>
            <span>{{ tool.last_test.duration }}ms</span>
            <span class="text-n-slate-9 mx-1">•</span>
            <span>{{ formatDate(tool.last_test.at) }}</span>
          </div>
          <div
            v-if="tool.last_test.error"
            class="text-red-500 mt-1 truncate max-w-md"
          >
            Erro: {{ tool.last_test.error }}
          </div>
        </template>
        <span v-else class="text-n-slate-9 italic"
          >Ferramenta nunca testada</span
        >
      </div>

      <div class="flex gap-2">
        <Button
          label="Testar Conexão"
          variant="outline"
          icon="i-lucide-play"
          size="sm"
          :is-loading="isTesting"
          @click="testConnection"
        />
        <Button
          v-if="hasChanges"
          label="Salvar Alterações"
          size="sm"
          icon="i-lucide-save"
          :is-loading="isSaving"
          @click="saveConfig"
        />
      </div>
    </div>

    <!-- Test Result Output -->
    <div
      v-if="testResult"
      class="mt-4 rounded-md border border-n-weak overflow-hidden text-sm animate-fade-in"
    >
      <div
        class="flex justify-between items-center px-4 py-2 bg-n-alpha-1 border-b border-n-weak"
      >
        <span
          class="font-bold"
          :class="testResult.success ? 'text-green-600' : 'text-red-500'"
        >
          {{ testResult.success ? 'SUCESSO' : 'FALHA' }}
        </span>
        <span class="font-mono text-xs text-n-slate-10">
          Duration: {{ testResult.duration_ms }}ms | Status:
          {{ testResult.status }}
        </span>
      </div>
      <div class="bg-n-solid-3 p-0">
        <pre
          class="overflow-auto max-h-60 p-4 text-xs font-mono text-n-slate-11 whitespace-pre-wrap break-all"
          >{{ formatJson(testResult.body || testResult.error) }}</pre
        >
      </div>
    </div>
  </div>
</template>
