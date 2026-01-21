<script setup>
/* eslint-disable @intlify/vue-i18n/no-raw-text, vue/no-bare-strings-in-template, vue/no-unused-emit-declarations */
import { computed, ref } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';

const props = defineProps({
  reservation: {
    type: Object,
    required: true,
  },
  layoutType: {
    type: String, // 'entry', 'exit', 'staying', 'issue', 'pre_booking', 'history'
    default: 'entry',
  },
  mode: {
    type: String,
    default: 'operational',
  },
});

const emit = defineEmits([
  'checkIn',
  'checkOut',
  'pay',
  'edit',
  'cancel',
  'viewConversation',
]);

const guestName = computed(() => props.reservation.contact_name || 'Hóspede');
const suiteName = computed(() => props.reservation.suite_identifier || 'S/N');

// Status Helpers
const isPaid = computed(() => props.reservation.payment_status === 'paid');
const isPartial = computed(
  () => props.reservation.payment_status === 'partial'
);
const isPending = computed(() => !isPaid.value && !isPartial.value);
const sourceTag = computed(() => props.reservation.source_tag || '');

// Relative Time Logic
const timeDisplay = computed(() => {
  const targetDate =
    props.layoutType === 'entry'
      ? new Date(props.reservation.check_in_at)
      : new Date(props.reservation.check_out_at);

  const now = new Date();
  const diffMs = targetDate - now;
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMins / 60);

  if (diffMins < 0) {
    if (Math.abs(diffHours) > 0) return `Atraso ${Math.abs(diffHours)}h`;
    return `Atraso ${Math.abs(diffMins)}m`;
  }

  if (diffHours > 0) {
    return `${diffHours}h ${diffMins % 60}m`;
  }

  return `${diffMins} min`;
});

const isLate = computed(() => {
  const targetDate =
    props.layoutType === 'entry'
      ? new Date(props.reservation.check_in_at)
      : new Date(props.reservation.check_out_at);
  return new Date() > targetDate;
});

const statusColor = computed(() => {
  if (props.reservation.status === 'scheduled')
    return 'border-l-4 border-blue-500';
  if (props.reservation.status === 'active')
    return 'border-l-4 border-emerald-500';
  if (props.reservation.status === 'completed')
    return 'border-l-4 border-slate-500';
  if (props.reservation.status === 'cancelled')
    return 'border-l-4 border-rose-500';
  return 'border-l-4 border-slate-300';
});

const formatCurrency = value => {
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'BRL',
  }).format(value || 0);
};

// Menu Actions
const menuItems = computed(() => {
  const items = [
    {
      label: 'Ver Conversa',
      action: 'viewConversation',
      icon: 'i-lucide-message-circle',
    },
    {
      label: 'Editar',
      action: 'edit',
      icon: 'i-lucide-pencil',
    },
  ];

  if (props.mode === 'operational') {
    items.unshift({
      label: 'Estender',
      action: 'extend',
      icon: 'i-lucide-arrow-right-circle',
    });
    if (props.reservation.status === 'active') {
      items.unshift({
        label: 'Fazer Check-out',
        action: 'checkOut',
        icon: 'i-lucide-log-out',
      });
    }
  } else if (props.mode === 'pre_booking') {
    items.push({
      label: 'Cancelar Pré-reserva',
      action: 'cancel',
      icon: 'i-lucide-x-circle',
      destructive: true,
    });
  } else if (props.mode === 'history') {
    // History usually limited actions
  } else {
    // Default fallback
    items.push({
      label: 'Cancelar',
      action: 'cancel',
      icon: 'i-lucide-x-circle',
      destructive: true,
    });
  }

  // Common destructive for operational if not history
  if (props.mode === 'operational') {
    items.push({
      label: 'Cancelar',
      action: 'cancel',
      icon: 'i-lucide-x-circle',
      destructive: true,
    });
  }

  return items;
});

const handleAction = item => {
  if (item.action === 'checkOut') {
    emit('checkOut', props.reservation);
  } else {
    emit(item.action, props.reservation);
  }
};

const showMenu = ref(false);
</script>

<template>
  <!-- eslint-disable @intlify/vue-i18n/no-raw-text, vue/no-bare-strings-in-template -->
  <div
    class="bg-white dark:bg-slate-900 rounded-lg shadow-sm border border-slate-200 dark:border-slate-800 p-3 hover:shadow-md transition-shadow relative"
    :class="[statusColor]"
  >
    <!-- Row 1: Suite + Time Badge -->
    <div class="flex justify-between items-center mb-1">
      <span
        class="text-sm font-black text-slate-700 dark:text-slate-200 uppercase tracking-widest flex items-center gap-1"
      >
        <i class="i-lucide-bed-double size-4" />
        {{ suiteName }}
      </span>

      <!-- Relative Time Badge -->
      <div
        class="text-xs font-bold px-1.5 py-0.5 rounded flex items-center gap-1"
        :class="
          isLate
            ? 'bg-rose-100 text-rose-700 dark:bg-rose-900/30 dark:text-rose-400'
            : 'bg-blue-50 text-blue-600 dark:bg-blue-900/20 dark:text-blue-300'
        "
      >
        <i class="i-lucide-clock size-3" />
        {{ timeDisplay }}
      </div>
    </div>

    <!-- Row 2: Guest Name -->
    <div class="mb-2 flex items-center gap-2 flex-wrap">
      <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
      <span
        class="font-bold text-slate-900 dark:text-slate-100 text-base leading-tight line-clamp-2"
        :title="guestName"
      >
        {{ guestName }}
      </span>
      <span
        v-if="sourceTag"
        class="text-[10px] uppercase font-bold px-2 py-0.5 rounded-md inline-flex items-center border border-emerald-600 bg-emerald-400 text-slate-900"
      >
        {{ sourceTag }}
      </span>
    </div>

    <!-- Row 3: Financial + Channel -->
    <div class="flex justify-between items-end mb-3">
      <div class="flex flex-col">
        <span class="text-sm font-bold text-slate-900 dark:text-slate-100">
          {{ formatCurrency(reservation.total_amount) }}
        </span>

        <div
          class="flex items-center gap-1 text-[10px] uppercase font-bold px-1.5 py-0.5 rounded-sm w-fit"
          :class="{
            'bg-emerald-100 text-emerald-700': isPaid,
            'bg-amber-100 text-amber-700': isPending,
            'bg-blue-100 text-blue-700': isPartial,
          }"
        >
          <i
            class="size-3"
            :class="isPaid ? 'i-lucide-check-circle' : 'i-lucide-alert-circle'"
          />
          {{ isPaid ? 'Pago' : 'Pendente' }}
        </div>
      </div>

      <!-- Channel Icon (Placeholder for now, but clean) -->
      <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
      <div class="text-slate-400" title="Canal">
        <i class="i-lucide-message-circle size-4" />
      </div>
    </div>

    <!-- Actions Footer (Always Visible) -->
    <div
      class="flex items-center gap-2 pt-2 border-t border-slate-100 dark:border-slate-800"
    >
      <!-- Mode: PRE_BOOKING -->
      <template v-if="mode === 'pre_booking'">
        <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
        <Button
          v-if="!isPaid"
          size="xs"
          variant="solid"
          color="amber"
          class="flex-1 font-bold shadow-sm"
          @click="$emit('pay', reservation)"
        >
          <i class="i-lucide-dollar-sign mr-1" /> Cobrar
        </Button>
        <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
        <Button
          v-else
          size="xs"
          variant="outline"
          color="slate"
          class="flex-1"
          @click="$emit('edit', reservation)"
        >
          Detalhes
        </Button>
      </template>

      <!-- Mode: OPERATIONAL (Original Logic) -->
      <template v-else-if="mode === 'operational'">
        <Button
          v-if="layoutType === 'entry'"
          size="xs"
          variant="solid"
          color="teal"
          class="flex-1 font-bold shadow-sm"
          @click="$emit('checkIn', reservation)"
        >
          <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
          <i class="i-lucide-log-in mr-1" /> Check-in
        </Button>

        <Button
          v-else-if="layoutType === 'exit'"
          size="xs"
          variant="solid"
          color="ruby"
          class="flex-1 font-bold shadow-sm"
          @click="$emit('checkOut', reservation)"
        >
          <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
          <i class="i-lucide-log-out mr-1" /> Check-out
        </Button>

        <Button
          v-else
          size="xs"
          variant="outline"
          color="slate"
          class="flex-1"
          @click="$emit('edit', reservation)"
        >
          <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
          Detalhes
        </Button>
      </template>

      <!-- Mode: HISTORY / Default -->
      <template v-else>
        <Button
          size="xs"
          variant="outline"
          color="slate"
          class="flex-1"
          @click="$emit('edit', reservation)"
        >
          <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
          Detalhes
        </Button>
      </template>

      <!-- Operations Quick Pay (Only in Operational/History if unpaid) -->
      <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
      <Button
        v-if="mode !== 'pre_booking' && !isPaid"
        size="xs"
        variant="outline"
        color="amber"
        title="Receber Pagamento"
        @click="$emit('pay', reservation)"
      >
        <i class="i-lucide-dollar-sign" />
      </Button>

      <!-- More Actions Menu -->
      <div v-on-clickaway="() => (showMenu = false)" class="relative">
        <Button
          size="xs"
          variant="ghost"
          color="slate"
          icon="i-lucide-more-vertical"
          @click="showMenu = !showMenu"
        />
        <DropdownMenu
          v-if="showMenu"
          :menu-items="menuItems"
          class="right-0 mt-1 w-48 top-full z-10"
          @action="handleAction"
        />
      </div>
    </div>
  </div>
</template>
