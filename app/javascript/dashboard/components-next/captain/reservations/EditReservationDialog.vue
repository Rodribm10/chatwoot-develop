<script setup>
import { reactive, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';

const props = defineProps({
  reservation: {
    type: Object,
    required: true,
  },
  units: {
    type: Array,
    default: () => [],
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['confirm', 'close']);

const { t } = useI18n();

const form = reactive({
  suite_identifier: '',
  check_in_at: '',
  check_out_at: '',
  total_amount: 0,
  status: '',
  captain_unit_id: '',
});

const statusOptions = [
  { value: 'scheduled', label: 'Agendada' },
  { value: 'active', label: 'Confirmada' },
  { value: 'pending_payment', label: 'Pendente Pagamento' },
  { value: 'cancelled', label: 'Cancelada' },
  { value: 'completed', label: 'Concluída' },
];

const formatDateTimeForInput = dateString => {
  if (!dateString) return '';
  const date = new Date(dateString);
  const tzoffset = date.getTimezoneOffset() * 60000;
  const localISOTime = new Date(date.getTime() - tzoffset)
    .toISOString()
    .slice(0, 16);
  return localISOTime;
};

onMounted(() => {
  form.suite_identifier = props.reservation.suite_identifier || '';
  form.check_in_at = formatDateTimeForInput(props.reservation.check_in_at);
  form.check_out_at = formatDateTimeForInput(props.reservation.check_out_at);
  form.total_amount = props.reservation.total_amount || 0;
  form.status = props.reservation.status || 'scheduled';
  form.captain_unit_id =
    props.reservation.unit?.id || props.reservation.captain_unit_id || '';
});

const handleSubmit = () => {
  emit('confirm', { ...form });
};
</script>

<template>
  <Dialog
    :title="t('CAPTAIN.RESERVATIONS.EDIT.TITLE')"
    :description="t('CAPTAIN.RESERVATIONS.EDIT.DESCRIPTION')"
    :confirm-button-label="t('CAPTAIN.RESERVATIONS.EDIT.CONFIRM')"
    :is-loading="isLoading"
    @confirm="handleSubmit"
    @close="$emit('close')"
  >
    <div class="flex flex-col gap-4">
      <!-- Unit -->
      <div class="flex flex-col gap-1 text-sm">
        <label class="font-medium text-n-slate-12">
          {{ t('CAPTAIN.RESERVATIONS.FORM.UNIT_LABEL') }}
        </label>
        <select
          v-model="form.captain_unit_id"
          class="w-full h-10 px-3 rounded-lg border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-sm focus:ring-1 focus:ring-blue-500 outline-none"
        >
          <option value="">
            {{ t('CAPTAIN.RESERVATIONS.FORM.UNIT_PLACEHOLDER') }}
          </option>
          <option v-for="unit in units" :key="unit.id" :value="unit.id">
            {{ unit.name }}
          </option>
        </select>
      </div>

      <!-- Suite -->
      <Input
        v-model="form.suite_identifier"
        :label="t('CAPTAIN.RESERVATIONS.FORM.SUITE_LABEL')"
        :placeholder="t('CAPTAIN.RESERVATIONS.FORM.SUITE_PLACEHOLDER')"
      />

      <!-- Dates -->
      <div class="grid grid-cols-2 gap-4">
        <Input
          v-model="form.check_in_at"
          type="datetime-local"
          :label="t('CAPTAIN.RESERVATIONS.AUTOMATIONS.TRIGGER_CHECK_IN')"
        />
        <Input
          v-model="form.check_out_at"
          type="datetime-local"
          :label="t('CAPTAIN.RESERVATIONS.AUTOMATIONS.TRIGGER_CHECK_OUT')"
        />
      </div>

      <!-- Price & Status -->
      <div class="grid grid-cols-2 gap-4">
        <Input
          v-model="form.total_amount"
          type="number"
          :label="t('CAPTAIN.RESERVATIONS.FORM.TOTAL_AMOUNT_LABEL')"
          placeholder="0.00"
        />
        <div class="flex flex-col gap-1 text-sm">
          <label class="font-medium text-n-slate-12">
            {{ t('CAPTAIN.RESPONSES.STATUS.TITLE') }}
          </label>
          <select
            v-model="form.status"
            class="w-full h-10 px-3 rounded-lg border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-sm focus:ring-1 focus:ring-blue-500 outline-none"
          >
            <option
              v-for="option in statusOptions"
              :key="option.value"
              :value="option.value"
            >
              {{ option.label }}
            </option>
          </select>
        </div>
      </div>
    </div>
  </Dialog>
</template>
