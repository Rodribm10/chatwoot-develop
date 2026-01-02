<script setup>
import { computed, onMounted, ref } from 'vue';
import { useRoute } from 'vue-router';
import { useStore } from 'dashboard/composables/store';
import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import WootSwitch from 'dashboard/components-next/switch/Switch.vue';

const route = useRoute();
const store = useStore();

const tools = ref([]);
const isFetching = ref(false);
const isUpdating = ref({});

const assistantId = computed(() => route.params.assistantId);

const fetchTools = async () => {
  isFetching.value = true;
  try {
    const data = await store.dispatch('captainAssistants/fetchTools', {
      assistantId: assistantId.value,
    });
    tools.value = data || [];
  } catch (e) {
    tools.value = [];
  } finally {
    isFetching.value = false;
  }
};

const handleConfigUpdate = async tool => {
  if (!tool.enabled) return;
  handleUpdate(tool);
};

const handleUpdate = async tool => {
  isUpdating.value = { ...isUpdating.value, [tool.key]: true };
  try {
    await store.dispatch('captainAssistants/updateTool', {
      assistantId: assistantId.value,
      toolKey: tool.key,
      config: {
        enabled: tool.enabled,
        webhook_url: tool.webhook_url,
        plug_play_id: tool.plug_play_id,
        plug_play_token: tool.plug_play_token,
      },
    });
  } catch (e) {
    // Optionally handle error
  } finally {
    isUpdating.value = { ...isUpdating.value, [tool.key]: false };
  }
};

onMounted(() => {
  fetchTools();
});
</script>

<template>
  <PageLayout
    header-title="Assistant Skills"
    :header-description="'Configure the capabilities and tools available to this assistant.'"
    :is-fetching="isFetching"
    :show-pagination-footer="false"
  >
    <template #body>
      <div v-if="tools && tools.length" class="flex flex-col gap-6 max-w-[80rem]">
        <div
          v-for="tool in tools"
          :key="tool.key"
          class="border border-n-weak rounded-md p-6 bg-slate-50 dark:bg-slate-900"
        >
          <div class="flex justify-between items-start">
            <div class="flex-1 pr-4">
              <h4 class="text-base font-semibold text-n-slate-12 mb-1">
                {{ tool.name }}
              </h4>
              <p class="text-sm text-n-slate-11">{{ tool.description }}</p>
            </div>
            <div class="flex items-center gap-3">
              <span
                v-if="isUpdating[tool.key]"
                class="text-xs text-n-slate-10 animate-pulse"
              >
                Saving...
              </span>
              <WootSwitch
                v-model="tool.enabled"
                @change="handleUpdate(tool)"
              />
            </div>
          </div>

          <div
            v-if="tool.enabled"
            class="flex flex-col gap-4 pl-4 border-l-2 border-n-weak mt-6 pt-2 transition-all"
          >
            <h5 class="text-xs font-bold uppercase text-n-slate-10 tracking-wider">
              Configuration
            </h5>

            <Input
              v-model="tool.webhook_url"
              label="Webhook URL"
              placeholder="https://oxpi.com.br/api/..."
              @blur="handleConfigUpdate(tool)"
            />

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <Input
                v-model="tool.plug_play_id"
                label="Plug&Play Client ID"
                placeholder="Client ID"
                @blur="handleConfigUpdate(tool)"
              />
              <Input
                v-model="tool.plug_play_token"
                label="Plug&Play Token"
                placeholder="Token"
                type="password"
                @blur="handleConfigUpdate(tool)"
              />
            </div>
          </div>
        </div>
      </div>
      <div v-else-if="!isFetching" class="p-10 text-center text-n-slate-11">
        No skills available for this assistant.
      </div>
    </template>
  </PageLayout>
</template>
