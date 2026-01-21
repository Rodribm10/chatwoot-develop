<script setup>
import { computed, h, ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { picoSearch } from '@scmmishra/pico-search';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import SelectMenu from 'dashboard/components-next/selectmenu/SelectMenu.vue';

import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import SettingsHeader from 'dashboard/components-next/captain/pageComponents/settings/SettingsHeader.vue';
import SuggestedScenarios from 'dashboard/components-next/captain/assistant/SuggestedRules.vue';
import ScenariosCard from 'dashboard/components-next/captain/assistant/ScenariosCard.vue';
import BulkSelectBar from 'dashboard/components-next/captain/assistant/BulkSelectBar.vue';
import AddNewScenariosDialog from 'dashboard/components-next/captain/assistant/AddNewScenariosDialog.vue';

const { t } = useI18n();
const route = useRoute();
const store = useStore();
const { uiSettings, updateUISettings } = useUISettings();
const { formatMessage } = useMessageFormatter();
const assistantId = computed(() => Number(route.params.assistantId));

const uiFlags = useMapGetter('captainScenarios/getUIFlags');
const isFetching = computed(() => uiFlags.value.fetchingList);
const scenarios = useMapGetter('captainScenarios/getRecords');
const assistants = useMapGetter('captainAssistants/getRecords');

const searchQuery = ref('');
const duplicateDialogRef = ref(null);
const duplicateScenario = ref(null);
const duplicateTargetId = ref(null);

const LINK_INSTRUCTION_CLASS =
  '[&_a[href^="tool://"]]:text-n-iris-11 [&_a:not([href^="tool://"])]:text-n-slate-12 [&_a]:pointer-events-none [&_a]:cursor-default';

const renderInstruction = instruction =>
  h('span', {
    class: `text-sm text-n-slate-12 py-4 prose prose-sm min-w-0 break-words ${LINK_INSTRUCTION_CLASS}`,
    innerHTML: instruction,
  });

// Suggested example scenarios for quick add
const scenariosExample = computed(() => [
  {
    id: 1,
    title: t('CAPTAIN.ASSISTANTS.SCENARIOS.EXAMPLES.PROSPECTIVE_BUYER.TITLE'),
    description: t(
      'CAPTAIN.ASSISTANTS.SCENARIOS.EXAMPLES.PROSPECTIVE_BUYER.DESCRIPTION'
    ),
    instruction: t(
      'CAPTAIN.ASSISTANTS.SCENARIOS.EXAMPLES.PROSPECTIVE_BUYER.INSTRUCTION'
    ),
    tools: ['add_private_note', 'add_label_to_conversation', 'handoff'],
  },
]);

const filteredScenarios = computed(() => {
  const query = searchQuery.value.trim();
  const source = scenarios.value;
  if (!query) return source;
  return picoSearch(source, query, ['title', 'description', 'instruction']);
});

const assistantOptions = computed(() =>
  assistants.value
    .filter(assistant => assistant.id !== assistantId.value)
    .map(assistant => ({
      label: assistant.name,
      value: assistant.id,
    }))
);

const selectedAssistantLabel = computed(() => {
  const option = assistantOptions.value.find(
    item => item.value === duplicateTargetId.value
  );
  return option?.label || t('CAPTAIN.ASSISTANTS.SCENARIOS.DUPLICATE.SELECT');
});

const shouldShowSuggestedRules = computed(() => {
  return uiSettings.value?.show_scenarios_suggestions !== false;
});

const closeSuggestedRules = () => {
  updateUISettings({ show_scenarios_suggestions: false });
};

// Bulk selection & hover state
const bulkSelectedIds = ref(new Set());
const hoveredCard = ref(null);

const handleRuleSelect = id => {
  const selected = new Set(bulkSelectedIds.value);
  selected[selected.has(id) ? 'delete' : 'add'](id);
  bulkSelectedIds.value = selected;
};

const buildSelectedCountLabel = computed(() => {
  const count = scenarios.value.length || 0;
  const isAllSelected = bulkSelectedIds.value.size === count && count > 0;
  return isAllSelected
    ? t('CAPTAIN.ASSISTANTS.SCENARIOS.BULK_ACTION.UNSELECT_ALL', { count })
    : t('CAPTAIN.ASSISTANTS.SCENARIOS.BULK_ACTION.SELECT_ALL', { count });
});

const selectedCountLabel = computed(() => {
  return t('CAPTAIN.ASSISTANTS.SCENARIOS.BULK_ACTION.SELECTED', {
    count: bulkSelectedIds.value.size,
  });
});

const handleRuleHover = (isHovered, id) => {
  hoveredCard.value = isHovered ? id : null;
};

const getToolsFromInstruction = instruction => [
  ...new Set(
    [...(instruction?.matchAll(/\(tool:\/\/([^)]+)\)/g) ?? [])].map(m => m[1])
  ),
];

const updateScenario = async scenario => {
  try {
    const instructionTools = getToolsFromInstruction(scenario.instruction);
    const combinedTools = [
      ...new Set([...(scenario.tools || []), ...instructionTools]),
    ];
    await store.dispatch('captainScenarios/update', {
      id: scenario.id,
      assistantId: assistantId.value,
      ...scenario,
      tools: combinedTools,
    });
    useAlert(t('CAPTAIN.ASSISTANTS.SCENARIOS.API.UPDATE.SUCCESS'));
  } catch (error) {
    const errorMessage =
      error?.response?.message ||
      t('CAPTAIN.ASSISTANTS.SCENARIOS.API.UPDATE.ERROR');
    useAlert(errorMessage);
  }
};

const deleteScenario = async id => {
  try {
    await store.dispatch('captainScenarios/delete', {
      id,
      assistantId: assistantId.value,
    });
    useAlert(t('CAPTAIN.ASSISTANTS.SCENARIOS.API.DELETE.SUCCESS'));
  } catch (error) {
    const errorMessage =
      error?.response?.message ||
      t('CAPTAIN.ASSISTANTS.SCENARIOS.API.DELETE.ERROR');
    useAlert(errorMessage);
  }
};

// TODO: Add bulk delete endpoint
const bulkDeleteScenarios = async ids => {
  const idsArray = ids || Array.from(bulkSelectedIds.value);
  await Promise.all(
    idsArray.map(id =>
      store.dispatch('captainScenarios/delete', {
        id,
        assistantId: assistantId.value,
      })
    )
  );
  bulkSelectedIds.value = new Set();
  useAlert(t('CAPTAIN.ASSISTANTS.SCENARIOS.API.DELETE.SUCCESS'));
};

const addScenario = async scenario => {
  try {
    const instructionTools = getToolsFromInstruction(scenario.instruction);
    const combinedTools = [
      ...new Set([...(scenario.tools || []), ...instructionTools]),
    ];
    await store.dispatch('captainScenarios/create', {
      assistantId: assistantId.value,
      ...scenario,
      tools: combinedTools,
    });
    useAlert(t('CAPTAIN.ASSISTANTS.SCENARIOS.API.ADD.SUCCESS'));
  } catch (error) {
    const errorMessage =
      error?.response?.message ||
      t('CAPTAIN.ASSISTANTS.SCENARIOS.API.ADD.ERROR');
    useAlert(errorMessage);
  }
};

const openDuplicateDialog = scenario => {
  if (!assistantOptions.value.length) {
    useAlert(t('CAPTAIN.ASSISTANTS.SCENARIOS.DUPLICATE.NO_TARGETS'));
    return;
  }

  duplicateScenario.value = scenario;
  duplicateTargetId.value = assistantOptions.value[0]?.value || null;
  duplicateDialogRef.value?.open();
};

const closeDuplicateDialog = () => {
  duplicateDialogRef.value?.close();
  duplicateScenario.value = null;
  duplicateTargetId.value = null;
};

const handleDuplicateConfirm = async () => {
  if (!duplicateScenario.value || !duplicateTargetId.value) return;

  try {
    const instructionTools = getToolsFromInstruction(
      duplicateScenario.value.instruction
    );
    const combinedTools = [
      ...new Set([
        ...(duplicateScenario.value.tools || []),
        ...instructionTools,
      ]),
    ];
    const titleSuffix = t('CAPTAIN.ASSISTANTS.SCENARIOS.DUPLICATE.COPY_SUFFIX');
    await store.dispatch('captainScenarios/create', {
      assistantId: duplicateTargetId.value,
      title: `${duplicateScenario.value.title}${titleSuffix}`,
      description: duplicateScenario.value.description,
      instruction: duplicateScenario.value.instruction,
      tools: combinedTools,
    });
    useAlert(t('CAPTAIN.ASSISTANTS.SCENARIOS.DUPLICATE.SUCCESS'));
    closeDuplicateDialog();
  } catch (error) {
    const errorMessage =
      error?.response?.message ||
      t('CAPTAIN.ASSISTANTS.SCENARIOS.DUPLICATE.ERROR');
    useAlert(errorMessage);
  }
};

const addAllExampleScenarios = async () => {
  try {
    scenariosExample.value.forEach(async scenario => {
      await store.dispatch('captainScenarios/create', {
        assistantId: assistantId.value,
        ...scenario,
      });
    });
    useAlert(t('CAPTAIN.ASSISTANTS.SCENARIOS.API.ADD.SUCCESS'));
  } catch (error) {
    const errorMessage =
      error?.response?.message ||
      t('CAPTAIN.ASSISTANTS.SCENARIOS.API.ADD.ERROR');
    useAlert(errorMessage);
  }
};

onMounted(() => {
  store.dispatch('captainScenarios/get', {
    assistantId: assistantId.value,
  });
  store.dispatch('captainAssistants/get', { page: 1 });
  store.dispatch('captainTools/getTools');
});
</script>

<template>
  <PageLayout
    :header-title="$t('CAPTAIN.DOCUMENTS.HEADER')"
    :is-fetching="isFetching"
    :show-know-more="false"
    :show-pagination-footer="false"
  >
    <template #body>
      <SettingsHeader
        :heading="$t('CAPTAIN.ASSISTANTS.SCENARIOS.TITLE')"
        :description="$t('CAPTAIN.ASSISTANTS.SCENARIOS.DESCRIPTION')"
      />
      <div v-if="shouldShowSuggestedRules" class="flex mt-7 flex-col gap-4">
        <SuggestedScenarios
          :title="$t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.SUGGESTED.TITLE')"
          :items="scenariosExample"
          @close="closeSuggestedRules"
          @add="addAllExampleScenarios"
        >
          <template #default="{ item }">
            <div class="flex items-center gap-3 justify-between">
              <span class="text-sm text-n-slate-12">
                {{ item.title }}
              </span>
              <Button
                :label="
                  $t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.SUGGESTED.ADD_SINGLE')
                "
                ghost
                xs
                slate
                class="!text-sm !text-n-slate-11 flex-shrink-0"
                @click="addScenario(item)"
              />
            </div>
            <div class="flex flex-col">
              <span class="text-sm text-n-slate-11 mt-2">
                {{ item.description }}
              </span>
              <component
                :is="renderInstruction(formatMessage(item.instruction, false))"
              />
              <span class="text-sm text-n-slate-11 font-medium mb-1">
                {{ t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.SUGGESTED.TOOLS_USED') }}
                {{ item.tools?.map(tool => `@${tool}`).join(', ') }}
              </span>
            </div>
          </template>
        </SuggestedScenarios>
      </div>
      <div class="flex mt-7 flex-col gap-4">
        <div class="flex justify-between items-center">
          <BulkSelectBar
            v-model="bulkSelectedIds"
            :all-items="scenarios"
            :select-all-label="buildSelectedCountLabel"
            :selected-count-label="selectedCountLabel"
            :delete-label="
              $t('CAPTAIN.ASSISTANTS.SCENARIOS.BULK_ACTION.BULK_DELETE_BUTTON')
            "
            @bulk-delete="bulkDeleteScenarios"
          />
          <div class="flex items-center gap-2 ml-auto">
            <div
              v-if="scenarios.length && bulkSelectedIds.size === 0"
              class="max-w-[22.5rem] w-full min-w-0"
            >
              <Input
                v-model="searchQuery"
                :placeholder="
                  t('CAPTAIN.ASSISTANTS.SCENARIOS.LIST.SEARCH_PLACEHOLDER')
                "
              />
            </div>
            <AddNewScenariosDialog
              trigger-label="CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.LOAD_TEMPLATE"
              trigger-icon="i-lucide-layout-template"
              start-with-templates
              trigger-faded
              @add="addScenario"
            />
            <AddNewScenariosDialog @add="addScenario" />
          </div>
        </div>
        <div v-if="scenarios.length === 0" class="mt-1 mb-2">
          <span class="text-n-slate-11 text-sm">
            {{ t('CAPTAIN.ASSISTANTS.SCENARIOS.EMPTY_MESSAGE') }}
          </span>
        </div>
        <div v-else-if="filteredScenarios.length === 0" class="mt-1 mb-2">
          <span class="text-n-slate-11 text-sm">
            {{ t('CAPTAIN.ASSISTANTS.SCENARIOS.SEARCH_EMPTY_MESSAGE') }}
          </span>
        </div>
        <div v-else class="flex flex-col gap-2">
          <ScenariosCard
            v-for="scenario in filteredScenarios"
            :id="scenario.id"
            :key="scenario.id"
            :title="scenario.title"
            :description="scenario.description"
            :instruction="scenario.instruction"
            :tools="scenario.tools"
            :trigger-keywords="scenario.trigger_keywords"
            :enabled="scenario.enabled"
            :is-selected="bulkSelectedIds.has(scenario.id)"
            :selectable="
              hoveredCard === scenario.id || bulkSelectedIds.size > 0
            "
            @select="handleRuleSelect"
            @delete="deleteScenario(scenario.id)"
            @update="updateScenario"
            @duplicate="openDuplicateDialog"
            @hover="isHovered => handleRuleHover(isHovered, scenario.id)"
          />
        </div>
      </div>
    </template>
    <Dialog
      ref="duplicateDialogRef"
      :title="t('CAPTAIN.ASSISTANTS.SCENARIOS.DUPLICATE.TITLE')"
      :description="t('CAPTAIN.ASSISTANTS.SCENARIOS.DUPLICATE.DESCRIPTION')"
      :confirm-button-label="
        t('CAPTAIN.ASSISTANTS.SCENARIOS.DUPLICATE.CONFIRM')
      "
      :disable-confirm-button="!duplicateTargetId"
      @confirm="handleDuplicateConfirm"
      @close="closeDuplicateDialog"
    >
      <div class="flex flex-col gap-4">
        <div class="text-sm text-n-slate-12">
          <span class="font-medium">
            {{ t('CAPTAIN.ASSISTANTS.SCENARIOS.DUPLICATE.SCENARIO_LABEL') }}
          </span>
          <span class="ml-2">
            {{ duplicateScenario?.title || '' }}
          </span>
        </div>
        <div class="flex flex-col gap-2">
          <label class="text-sm font-medium text-n-slate-12">
            {{ t('CAPTAIN.ASSISTANTS.SCENARIOS.DUPLICATE.TARGET_LABEL') }}
          </label>
          <SelectMenu
            v-model="duplicateTargetId"
            :options="assistantOptions"
            :label="selectedAssistantLabel"
            sub-menu-position="bottom"
          />
        </div>
      </div>
    </Dialog>
  </PageLayout>
</template>
