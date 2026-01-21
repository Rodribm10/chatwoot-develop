<script setup>
/* eslint-disable @intlify/vue-i18n/no-raw-text, vue/no-bare-strings-in-template */
import { ref, computed, onMounted } from 'vue';
import { useAlert } from 'dashboard/composables';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import DatePicker from 'dashboard/components/ui/DatePicker/DatePicker.vue';

const props = defineProps({
  units: {
    type: Array,
    default: () => [],
  },
  preSelectedUnitId: {
    type: [String, Number],
    default: null,
  },
  initialContact: {
    type: Object,
    default: null, // { name, phone_number, id }
  },
  mode: {
    type: String,
    default: 'operational', // 'operational' | 'pre_booking'
  },
});

const emit = defineEmits(['close', 'confirm']);

const alert = useAlert();

const isLoading = ref(false);

const formData = ref({
  unit_id: '',
  suite_identifier: '',
  contact_name: '',
  contact_phone_number: '',
  check_in_at: '',
  check_out_at: '',
  reservation_type: 'period', // 'period' | 'overnight'
  payment_status: 'pending', // 'paid' | 'partial' | 'pending'
  total_amount: '',
  notes: '',
});

// Initialization
onMounted(() => {
  if (props.preSelectedUnitId) {
    formData.value.unit_id = props.preSelectedUnitId;
  }
  if (props.initialContact) {
    formData.value.contact_name = props.initialContact.name || '';
    formData.value.contact_phone_number =
      props.initialContact.phone_number || '';
  }

  // Set default dates if needed
  const now = new Date();
  formData.value.check_in_at = now;
  // Default duration 3h
  const end = new Date(now.getTime() + 3 * 60 * 60 * 1000);
  formData.value.check_out_at = end;
});

const isPreBookingMode = computed(() => props.mode === 'pre_booking');

const modalTitle = computed(() =>
  isPreBookingMode.value ? 'Enviar para Pagamentos' : 'Nova Reserva Manual'
);

const confirmLabel = computed(() =>
  isPreBookingMode.value ? 'Enviar Pré-Reserva' : 'Criar Reserva'
);

const handleSubmit = async () => {
  if (!formData.value.unit_id) {
    alert('Selecione uma Unidade.');
    return;
  }
  if (!formData.value.suite_identifier && !isPreBookingMode.value) {
    alert('Identificação da Suíte é obrigatória no modo Operacional.');
    return;
  }

  emit('confirm', { ...formData.value });
};
</script>

<template>
  <!-- eslint-disable @intlify/vue-i18n/no-raw-text, vue/no-bare-strings-in-template -->
  <Dialog
    show
    :title="modalTitle"
    :confirm-button-label="confirmLabel"
    :is-loading="isLoading"
    width="max-w-xl"
    @close="$emit('close')"
    @confirm="handleSubmit"
  >
    <div class="flex flex-col gap-4">
      <!-- Unit Selection (Readonly if pre-selected in pre-booking, strictly) -->
      <div class="flex flex-col gap-1">
        <label
          class="block text-sm font-bold text-slate-700 dark:text-slate-200"
        >
          Unidade
        </label>
        <select
          v-model="formData.unit_id"
          class="h-10 px-3 rounded-lg border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-sm w-full outline-none focus:ring-2 focus:ring-blue-500"
        >
          <option value="" disabled>Selecione...</option>
          <option v-for="unit in units" :key="unit.id" :value="unit.id">
            {{ unit.name }}
          </option>
        </select>
      </div>

      <!-- Guest Info -->
      <div class="grid grid-cols-2 gap-4">
        <Input
          v-model="formData.contact_name"
          label="Nome do Hóspede"
          placeholder="Ex: João Silva"
        />
        <Input
          v-model="formData.contact_phone_number"
          label="Telefone / WhatsApp"
          placeholder="(00) 00000-0000"
        />
      </div>

      <!-- Suite & Type -->
      <div class="grid grid-cols-2 gap-4">
        <Input
          v-model="formData.suite_identifier"
          label="Suíte (Opcional na Pré-Reserva)"
          placeholder="Ex: 101"
        />
        <div class="flex flex-col gap-1">
          <label class="text-sm font-bold text-slate-700 dark:text-slate-200">
            Tipo
          </label>
          <select
            v-model="formData.reservation_type"
            class="h-10 px-3 rounded-lg border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-sm w-full outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="period">Período</option>
            <option value="overnight">Pernoite</option>
          </select>
        </div>
      </div>

      <!-- Dates -->
      <div class="grid grid-cols-2 gap-4">
        <div class="flex flex-col gap-1">
          <label class="text-sm font-bold text-slate-700 dark:text-slate-200">
            Check-in
          </label>
          <DatePicker
            v-model:value="formData.check_in_at"
            type="datetime"
            format="DD/MM/YYYY HH:mm"
            placeholder="Data Chegada"
          />
        </div>
        <div class="flex flex-col gap-1">
          <label class="text-sm font-bold text-slate-700 dark:text-slate-200">
            Check-out (Estimado)
          </label>
          <DatePicker
            v-model:value="formData.check_out_at"
            type="datetime"
            format="DD/MM/YYYY HH:mm"
            placeholder="Data Saída"
          />
        </div>
      </div>

      <!-- Financial -->
      <div class="grid grid-cols-2 gap-4">
        <Input
          v-model="formData.total_amount"
          label="Valor Total (R$)"
          type="number"
          placeholder="0,00"
        />
        <div class="flex flex-col gap-1">
          <label class="text-sm font-bold text-slate-700 dark:text-slate-200">
            Status Financeiro
          </label>
          <select
            v-model="formData.payment_status"
            class="h-10 px-3 rounded-lg border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-sm w-full outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="pending">Pendente (Não Pago)</option>
            <option value="partial">Sinal Pago</option>
            <option value="paid">Totalmente Pago</option>
          </select>
        </div>
      </div>

      <!-- Notes -->
      <div class="flex flex-col gap-1">
        <label class="text-sm font-bold text-slate-700 dark:text-slate-200">
          Observações
        </label>
        <textarea
          v-model="formData.notes"
          rows="2"
          class="p-3 rounded-lg border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-sm w-full outline-none focus:ring-2 focus:ring-blue-500"
          placeholder="Ex: Decoração especial, cliente VIP..."
        />
      </div>

      <div
        v-if="isPreBookingMode"
        class="bg-blue-50 text-blue-800 text-xs p-3 rounded-lg border border-blue-100"
      >
        <i class="i-lucide-info mr-1" />
        Esta reserva será criada no modo <b>Pré-Reserva</b> (Aguardando
        Pagamento/Pix).
      </div>
    </div>
  </Dialog>
</template>
