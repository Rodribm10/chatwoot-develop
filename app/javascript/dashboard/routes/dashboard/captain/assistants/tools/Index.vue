<script setup>
import { computed, onMounted, ref, nextTick } from 'vue';
import { useRoute } from 'vue-router';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import WootSwitch from 'dashboard/components-next/switch/Switch.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import CustomToolsPageEmptyState from 'dashboard/components-next/captain/pageComponents/emptyStates/CustomToolsPageEmptyState.vue';
import CreateCustomToolDialog from 'dashboard/components-next/captain/pageComponents/customTool/CreateCustomToolDialog.vue';
import CustomToolCard from 'dashboard/components-next/captain/pageComponents/customTool/CustomToolCard.vue';
import DeleteDialog from 'dashboard/components-next/captain/pageComponents/DeleteDialog.vue';

const route = useRoute();
const store = useStore();

const tools = ref([]);
const isFetching = ref(false);
const isUpdating = ref({});

const customTools = useMapGetter('captainCustomTools/getRecords');
const customToolsMeta = useMapGetter('captainCustomTools/getMeta');

const createDialogRef = ref(null);
const deleteDialogRef = ref(null);
const selectedTool = ref(null);
const dialogType = ref('');

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

const handleConfigUpdate = async tool => {
  if (!tool.enabled) return;
  handleUpdate(tool);
};
const fetchCustomTools = (page = 1) => {
  store.dispatch('captainCustomTools/get', { page });
};

const openCreateDialog = () => {
  dialogType.value = 'create';
  selectedTool.value = null;
  nextTick(() => createDialogRef.value.dialogRef.open());
};

const handleEdit = tool => {
  dialogType.value = 'edit';
  selectedTool.value = tool;
  nextTick(() => createDialogRef.value.dialogRef.open());
};

const handleDelete = tool => {
  selectedTool.value = tool;
  nextTick(() => deleteDialogRef.value.dialogRef.open());
};

const handleAction = ({ action, id }) => {
  const tool = customTools.value.find(t => t.id === id);
  if (action === 'edit') {
    handleEdit(tool);
  } else if (action === 'delete') {
    handleDelete(tool);
  }
};

const handleDialogClose = () => {
  dialogType.value = '';
  selectedTool.value = null;
};

const onDeleteSuccess = () => {
  selectedTool.value = null;
  if (customTools.value.length === 1 && customToolsMeta.value.page > 1) {
    fetchCustomTools(customToolsMeta.value.page - 1);
  } else {
    fetchCustomTools(customToolsMeta.value.page);
  }
};

onMounted(() => {
  fetchTools();
  fetchCustomTools();
});
</script>

<template>
  <PageLayout
    :header-title="$t('CAPTAIN.ASSISTANTS.SKILLS.HEADER')"
    :header-description="$t('CAPTAIN.ASSISTANTS.SKILLS.DESCRIPTION')"
    :is-fetching="isFetching"
    :show-pagination-footer="false"
  >
    <template #body>
      <div
        v-if="tools && tools.length"
        class="flex flex-col gap-6 max-w-[80rem]"
      >
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
                {{ $t('CAPTAIN.ASSISTANTS.SKILLS.SAVING') }}
              </span>
              <WootSwitch v-model="tool.enabled" @change="handleUpdate(tool)" />
            </div>
          </div>

          <div
            v-if="tool.enabled"
            class="flex flex-col gap-4 pl-4 border-l-2 border-n-weak mt-6 pt-2 transition-all"
          >
            <h5
              class="text-xs font-bold uppercase text-n-slate-10 tracking-wider"
            >
              {{ $t('CAPTAIN.ASSISTANTS.SKILLS.CONFIGURATION') }}
            </h5>

            <Input
              v-model="tool.webhook_url"
              :label="$t('CAPTAIN.ASSISTANTS.SKILLS.WEBHOOK_URL.LABEL')"
              :placeholder="
                $t('CAPTAIN.ASSISTANTS.SKILLS.WEBHOOK_URL.PLACEHOLDER')
              "
              @blur="handleConfigUpdate(tool)"
            />

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <Input
                v-model="tool.plug_play_id"
                :label="$t('CAPTAIN.ASSISTANTS.SKILLS.PLUG_PLAY_ID.LABEL')"
                :placeholder="
                  $t('CAPTAIN.ASSISTANTS.SKILLS.PLUG_PLAY_ID.PLACEHOLDER')
                "
                @blur="handleConfigUpdate(tool)"
              />
              <Input
                v-model="tool.plug_play_token"
                :label="$t('CAPTAIN.ASSISTANTS.SKILLS.PLUG_PLAY_TOKEN.LABEL')"
                :placeholder="
                  $t('CAPTAIN.ASSISTANTS.SKILLS.PLUG_PLAY_TOKEN.PLACEHOLDER')
                "
                type="password"
                @blur="handleConfigUpdate(tool)"
              />
            </div>
          </div>
        </div>
      </div>
      <div v-else-if="!isFetching" class="p-10 text-center text-n-slate-11">
        {{ $t('CAPTAIN.ASSISTANTS.SKILLS.EMPTY_STATE') }}
      </div>

      <div class="mt-10 flex flex-col gap-6 max-w-[80rem]">
        <div class="flex items-center justify-between">
          <div class="flex flex-col gap-1">
            <h4 class="text-base font-semibold text-n-slate-12">
              {{ $t('CAPTAIN.CUSTOM_TOOLS.HEADER') }}
            </h4>
            <p class="text-sm text-n-slate-11">
              {{ $t('CAPTAIN.CUSTOM_TOOLS.EMPTY_STATE.SUBTITLE') }}
            </p>
          </div>
          <Button
            :label="$t('CAPTAIN.CUSTOM_TOOLS.ADD_NEW')"
            icon="i-lucide-plus"
            @click="openCreateDialog"
          />
        </div>

        <div
          v-if="customTools && customTools.length"
          class="flex flex-col gap-4"
        >
          <CustomToolCard
            v-for="tool in customTools"
            :id="tool.id"
            :key="tool.id"
            :title="tool.title"
            :description="tool.description"
            :endpoint-url="tool.endpoint_url"
            :http-method="tool.http_method"
            :auth-type="tool.auth_type"
            :param-schema="tool.param_schema"
            :enabled="tool.enabled"
            :created-at="tool.created_at"
            :updated-at="tool.updated_at"
            @action="handleAction"
          />
        </div>
        <div v-else class="p-6 rounded-md border border-n-weak">
          <CustomToolsPageEmptyState @click="openCreateDialog" />
        </div>
      </div>
    </template>
  </PageLayout>

  <CreateCustomToolDialog
    v-if="dialogType"
    ref="createDialogRef"
    :type="dialogType"
    :selected-tool="selectedTool"
    @close="handleDialogClose"
  />

  <DeleteDialog
    v-if="selectedTool"
    ref="deleteDialogRef"
    :entity="selectedTool"
    type="CustomTools"
    translation-key="CUSTOM_TOOLS"
    @delete-success="onDeleteSuccess"
  />
</template>
