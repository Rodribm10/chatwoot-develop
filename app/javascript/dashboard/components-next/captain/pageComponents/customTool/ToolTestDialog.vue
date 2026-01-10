<script setup>
import { ref, computed } from 'vue';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Label from 'dashboard/components-next/input/Label.vue';
import Spinner from 'shared/components/Spinner.vue';
import CaptainCustomToolsAPI from 'dashboard/api/captain/customTools';

const props = defineProps({
  tool: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['close']);
const { t } = useI18n();

const dialogRef = ref(null);
const isLoading = ref(false);
const testResult = ref(null);
const testParams = ref({});

// Initialize params based on schema
if (props.tool.param_schema) {
  props.tool.param_schema.forEach(param => {
    testParams.value[param.name] = '';
  });
}

const hasParams = computed(() => props.tool.param_schema && props.tool.param_schema.length > 0);

const handleClose = () => {
  emit('close');
};

const runTest = async () => {
  isLoading.value = true;
  testResult.value = null;
  try {
    const { data } = await CaptainCustomToolsAPI.test(props.tool.id, testParams.value);
    testResult.value = data;
  } catch (error) {
    useAlert(t('CAPTAIN.CUSTOM_TOOLS.TEST.ERROR_MESSAGE'));
  } finally {
    isLoading.value = false;
  }
};

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    width="3xl"
    :title="$t('CAPTAIN.CUSTOM_TOOLS.TEST.TITLE', { name: tool.title })"
    :show-cancel-button="false"
    :show-confirm-button="false"
    @close="handleClose"
  >
    <div class="flex flex-col gap-6">
      <!-- Params Section -->
      <div v-if="hasParams" class="flex flex-col gap-4 p-4 border rounded-lg border-n-slate-3 bg-n-slate-1">
        <h4 class="text-sm font-medium text-n-slate-12">
          {{ $t('CAPTAIN.CUSTOM_TOOLS.TEST.PARAMETERS') }}
        </h4>
        <div class="grid grid-cols-2 gap-4">
          <div v-for="param in tool.param_schema" :key="param.name" class="flex flex-col gap-1">
            <Label :label="param.name" :required="param.required" />
            <Input
              v-model="testParams[param.name]"
              :placeholder="param.description"
              type="text"
            />
          </div>
        </div>
      </div>

      <!-- Action Button -->
      <div class="flex justify-end">
        <Button
          :label="isLoading ? $t('CAPTAIN.CUSTOM_TOOLS.TEST.TESTING') : $t('CAPTAIN.CUSTOM_TOOLS.TEST.RUN_TEST')"
          :icon="isLoading ? '' : 'i-lucide-play'"
          color="blue"
          :disabled="isLoading"
          @click="runTest"
        >
          <template v-if="isLoading" #prefix>
            <Spinner size="sm" class="text-white" />
          </template>
        </Button>
      </div>

      <!-- Results Section -->
      <div v-if="testResult" class="flex flex-col gap-2">
        <div class="flex items-center gap-2">
          <span
            class="px-2 py-0.5 text-xs font-medium rounded"
            :class="
              testResult.success
                ? 'bg-green-100 text-green-700'
                : 'bg-red-100 text-red-700'
            "
          >
            {{ testResult.status }} {{ testResult.success ? 'OK' : 'Fail' }}
          </span>
          <span class="text-xs text-n-slate-11">
            {{ $t('CAPTAIN.CUSTOM_TOOLS.TEST.RESPONSE_TIME', { ms: 'N/A' }) }}
          </span>
        </div>

        <!-- Headers -->
        <div class="flex flex-col gap-1">
          <span class="text-xs font-medium text-n-slate-11">
            {{ $t('CAPTAIN.CUSTOM_TOOLS.TEST.RESPONSE_HEADERS') }}
          </span>
          <pre
            class="p-3 overflow-x-auto text-xs rounded bg-n-slate-2 text-n-slate-11 font-mono max-h-32"
          >{{ JSON.stringify(testResult.headers, null, 2) }}</pre>
        </div>

        <!-- Body -->
        <div class="flex flex-col gap-1">
          <span class="text-xs font-medium text-n-slate-11">
            {{ $t('CAPTAIN.CUSTOM_TOOLS.TEST.RESPONSE_BODY') }}
          </span>
          <pre
            class="p-3 overflow-x-auto text-xs rounded bg-n-slate-2 text-n-slate-12 font-mono max-h-96"
          >{{ testResult.body }}</pre>
        </div>
      </div>
    </div>

    <template #footer />
  </Dialog>
</template>
