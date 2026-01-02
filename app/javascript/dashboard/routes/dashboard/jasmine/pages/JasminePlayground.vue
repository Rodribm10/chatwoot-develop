<script setup>
import { ref, computed } from 'vue';
import { useStoreGetters } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import JasmineAPI from 'dashboard/api/inbox/jasmine';

import SettingsLayout from 'dashboard/routes/dashboard/settings/SettingsLayout.vue';
import BaseSettingsHeader from 'dashboard/routes/dashboard/settings/components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const getters = useStoreGetters();

// State
const selectedInboxId = ref(null);
const messages = ref([]);
const inputMessage = ref('');
const isLoading = ref(false);

// Computed
const inboxes = computed(() => getters['inboxes/getInboxes'].value);

const selectedInbox = computed(() => {
  if (!selectedInboxId.value) return null;
  return inboxes.value.find(i => i.id === selectedInboxId.value);
});

// Methods
const sendMessage = async () => {
  if (!inputMessage.value.trim() || !selectedInboxId.value) return;

  const userMessage = inputMessage.value.trim();
  messages.value.push({ role: 'user', content: userMessage });
  inputMessage.value = '';
  isLoading.value = true;

  try {
    const { data } = await JasmineAPI.testPlayground(
      selectedInboxId.value,
      userMessage
    );

    messages.value.push({
      role: 'assistant',
      content: data.response,
      debug: data.debug,
    });
  } catch (error) {
    const errorMsg =
      error.response?.data?.error || 'Erro ao processar mensagem';
    messages.value.push({ role: 'error', content: errorMsg });
    useAlert(errorMsg);
  } finally {
    isLoading.value = false;
  }
};

const clearChat = () => {
  messages.value = [];
};
</script>

<template>
  <SettingsLayout :is-loading="false">
    <template #header>
      <BaseSettingsHeader
        title="Playground Jasmine AI"
        description="Teste as respostas da Jasmine em tempo real antes de ativar para os clientes."
      />
    </template>

    <template #body>
      <div class="flex flex-col h-[calc(100vh-200px)] max-w-4xl">
        <!-- Inbox Selector -->
        <div class="mb-4">
          <label class="block text-sm font-medium text-n-slate-12 mb-2">
            Selecione uma Inbox para testar
          </label>
          <select
            v-model="selectedInboxId"
            class="w-full max-w-md px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-solid-1 text-n-slate-12"
          >
            <option :value="null">Escolha uma inbox...</option>
            <option v-for="inbox in inboxes" :key="inbox.id" :value="inbox.id">
              {{ inbox.name }}
            </option>
          </select>
          <p v-if="selectedInbox" class="text-xs text-n-slate-11 mt-1">
            ⚠️ Certifique-se de que a Jasmine está ativada e configurada para
            esta inbox
          </p>
        </div>

        <!-- Chat Container -->
        <div
          v-if="selectedInboxId"
          class="flex-1 flex flex-col border border-n-weak rounded-lg bg-n-solid-1 overflow-hidden"
        >
          <!-- Messages -->
          <div class="flex-1 overflow-y-auto p-4 space-y-4">
            <div
              v-if="messages.length === 0"
              class="text-center text-n-slate-11 py-12"
            >
              <span class="i-lucide-message-square size-12 mb-4 opacity-50" />
              <p>Envie uma mensagem para testar a Jasmine</p>
              <p class="text-xs mt-2">
                Experimente: "Olá", "Quanto custa?", "Como funciona?"
              </p>
            </div>

            <div
              v-for="(msg, index) in messages"
              :key="index"
              :class="[
                'max-w-[80%] rounded-lg p-3',
                msg.role === 'user'
                  ? 'ml-auto bg-n-blue-9 text-white'
                  : msg.role === 'error'
                    ? 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400'
                    : 'bg-n-alpha-3 text-n-slate-12',
              ]"
            >
              <p class="text-sm whitespace-pre-wrap">{{ msg.content }}</p>
              <div
                v-if="msg.debug"
                class="mt-2 pt-2 border-t border-n-weak text-xs text-n-slate-11"
              >
                <span class="font-mono"
                  >{{ msg.debug.model }} | temp:
                  {{ msg.debug.temperature }}</span
                >
              </div>
            </div>

            <div
              v-if="isLoading"
              class="flex items-center gap-2 text-n-slate-11"
            >
              <span class="i-lucide-loader-2 size-4 animate-spin" />
              <span class="text-sm">Jasmine está pensando...</span>
            </div>
          </div>

          <!-- Input -->
          <div class="border-t border-n-weak p-4">
            <div class="flex gap-2">
              <input
                v-model="inputMessage"
                type="text"
                class="flex-1 px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-solid-1 text-n-slate-12"
                placeholder="Digite uma mensagem de teste..."
                :disabled="isLoading"
                @keyup.enter="sendMessage"
              />
              <Button
                icon="i-lucide-send"
                :disabled="isLoading || !inputMessage.trim()"
                @click="sendMessage"
              />
              <Button
                v-tooltip="'Limpar conversa'"
                icon="i-lucide-trash-2"
                faded
                slate
                :disabled="messages.length === 0"
                @click="clearChat"
              />
            </div>
          </div>
        </div>

        <!-- No inbox selected -->
        <div
          v-else
          class="flex-1 flex items-center justify-center text-n-slate-11"
        >
          <div class="text-center">
            <span class="i-lucide-inbox size-16 mb-4 opacity-30" />
            <p>Selecione uma inbox acima para começar a testar</p>
          </div>
        </div>
      </div>
    </template>
  </SettingsLayout>
</template>
