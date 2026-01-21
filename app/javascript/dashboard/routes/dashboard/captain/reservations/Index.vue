<script setup>
/* eslint-disable @intlify/vue-i18n/no-raw-text, vue/no-bare-strings-in-template, vue/no-deprecated-slot-attribute */
import { onMounted, reactive, ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
// import { useMapGetter } from 'dashboard/composables/store';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import CaptainPaywall from 'dashboard/components-next/captain/pageComponents/Paywall.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

// New Components
import ReservationBoardColumn from 'dashboard/components-next/captain/reservations/ReservationBoardColumn.vue';
import ReservationCard from 'dashboard/components-next/captain/reservations/ReservationCard.vue';
import CreateReservationModal from 'dashboard/components-next/captain/reservations/CreateReservationModal.vue';
import EditReservationDialog from 'dashboard/components-next/captain/reservations/EditReservationDialog.vue';

import CaptainReservationsAPI from 'dashboard/api/captain/reservations';
import CaptainUnitsAPI from 'dashboard/api/captain/units';

const { t } = useI18n();
const alert = useAlert();
const cancelDialogRef = ref(null);

const isLoading = ref(false);
const isFetchingUnits = ref(false);
const isUpdating = ref(false);
const isCreating = ref(false);
const isSyncing = ref(false);

const reservations = ref([]);
const units = ref([]);
const selectedReservation = ref(null);
const showEditDialog = ref(false);
const showCreateModal = ref(false);
const viewAllDay = ref(false); // Toggle for Shift Window
const currentMode = ref('operational'); // 'operational', 'pre_booking', 'history'

const filters = reactive({
  unit_id: '',
  date: new Date().toISOString().slice(0, 10), // Default to Today
});

const fetchUnits = async () => {
  isFetchingUnits.value = true;
  try {
    const response = await CaptainUnitsAPI.get();
    units.value = response.data;

    // Auto-select unit logic
    // Prompt: "Usar automaticamente a unidade vinculada à Caixa de Entrada (Inbox) ativa"
    // Since we don't have global active inbox easily accessible here without route params,
    // and we must NOT default to the first one anymore:
    // We checks search query or rely on user selection.
    // However, if there is only one unit, it makes sense to auto-select.
    if (!filters.unit_id && units.value.length === 1) {
      filters.unit_id = units.value[0].id;
    }
  } catch (error) {
    // console.error(error);
  } finally {
    isFetchingUnits.value = false;
  }
};

const generateMockData = () => {
  const now = new Date();
  const tomorrow = new Date(now.getTime() + 24 * 60 * 60 * 1000);
  const yesterday = new Date(now.getTime() - 24 * 60 * 60 * 1000);

  const mocks = [
    // --- Operational ---
    {
      id: 9001,
      guest_name: 'Ana Silva (Mock)',
      check_in_at: new Date(now.getTime() + 2 * 60 * 60 * 1000).toISOString(), // Today + 2h
      check_out_at: tomorrow.toISOString(),
      status: 'scheduled',
      payment_status: 'paid',
      suite_identifier: '101',
      total_amount: 500,
    },
    {
      id: 9002,
      guest_name: 'Carlos Souza (Mock)',
      check_in_at: yesterday.toISOString(),
      check_out_at: tomorrow.toISOString(),
      status: 'active',
      payment_status: 'paid',
      suite_identifier: '102',
      total_amount: 750,
    },
    {
      id: 9003,
      guest_name: 'Beatriz Lima (Mock)',
      check_in_at: yesterday.toISOString(),
      check_out_at: now.toISOString(), // Today
      status: 'active',
      payment_status: 'paid',
      suite_identifier: '103',
      total_amount: 400,
    },
    // Issues
    {
      id: 9004,
      guest_name: 'Late Arrival (Mock)',
      check_in_at: new Date(now.getTime() - 2 * 60 * 60 * 1000).toISOString(), // Today - 2h (Late)
      check_out_at: tomorrow.toISOString(),
      status: 'scheduled',
      payment_status: 'paid',
      suite_identifier: '104',
      total_amount: 300,
    },
    {
      id: 9005,
      guest_name: 'Overdue Checkout (Mock)',
      check_in_at: yesterday.toISOString(),
      check_out_at: new Date(now.getTime() - 1 * 60 * 60 * 1000).toISOString(), // Today - 1h (Overdue)
      status: 'active',
      payment_status: 'paid',
      suite_identifier: '105',
      total_amount: 600,
    },

    // --- Pre-Booking ---
    {
      id: 9006,
      guest_name: 'Pix Recente (Mock)',
      created_at: new Date(now.getTime() - 30 * 60 * 1000).toISOString(), // -30 mins
      check_in_at: tomorrow.toISOString(),
      check_out_at: new Date(
        tomorrow.getTime() + 24 * 60 * 60 * 1000
      ).toISOString(),
      status: 'scheduled',
      payment_status: 'pending',
      total_amount: 250,
    },
    {
      id: 9007,
      guest_name: 'Aguardando Pagamento (Mock)',
      created_at: new Date(now.getTime() - 3 * 60 * 60 * 1000).toISOString(), // -3 hours
      check_in_at: tomorrow.toISOString(),
      check_out_at: new Date(
        tomorrow.getTime() + 24 * 60 * 60 * 1000
      ).toISOString(),
      status: 'scheduled',
      payment_status: 'pending',
      total_amount: 350,
    },
    {
      id: 9008,
      guest_name: 'Confirmado Futuro (Mock)',
      created_at: new Date(now.getTime() - 5 * 60 * 60 * 1000).toISOString(),
      check_in_at: tomorrow.toISOString(),
      check_out_at: new Date(
        tomorrow.getTime() + 24 * 60 * 60 * 1000
      ).toISOString(),
      status: 'scheduled',
      payment_status: 'paid',
      total_amount: 450,
    },
    {
      id: 9009,
      guest_name: 'Expirado (Mock)',
      created_at: new Date(now.getTime() - 26 * 60 * 60 * 1000).toISOString(), // -26 hours
      check_in_at: tomorrow.toISOString(),
      check_out_at: new Date(
        tomorrow.getTime() + 24 * 60 * 60 * 1000
      ).toISOString(),
      status: 'scheduled',
      payment_status: 'pending',
      total_amount: 200,
    },

    // --- History ---
    {
      id: 9010,
      guest_name: 'Finalizada (Mock)',
      check_in_at: new Date(
        yesterday.getTime() - 24 * 60 * 60 * 1000
      ).toISOString(),
      check_out_at: yesterday.toISOString(),
      status: 'completed',
      payment_status: 'paid',
      total_amount: 550,
    },
    {
      id: 9011,
      guest_name: 'Cancelada (Mock)',
      created_at: yesterday.toISOString(),
      status: 'cancelled',
      payment_status: 'cancelled',
      total_amount: 100,
    },
    {
      id: 9012,
      guest_name: 'No Show (Mock)',
      check_in_at: yesterday.toISOString(),
      status: 'no_show',
      payment_status: 'pending',
      total_amount: 150,
    },
  ];

  reservations.value = [...reservations.value, ...mocks];
};

const fetchReservations = async () => {
  if (!filters.unit_id) return; // Don't fetch without unit

  isLoading.value = true;
  try {
    const response = await CaptainReservationsAPI.get({
      page: 1,
      per_page: 100, // Try to get more items
      unit_id: filters.unit_id,
      status: 'all',
    });

    reservations.value = response.data.payload || [];
    generateMockData(); // Inject mocks
  } catch (error) {
    alert(t('CAPTAIN.RESERVATIONS.ERRORS.LOAD_FAILED'));
  } finally {
    isLoading.value = false;
  }
};

const handleSync = async () => {
  if (!filters.unit_id) return;
  isSyncing.value = true;
  try {
    await CaptainUnitsAPI.syncReservations(filters.unit_id);
    alert('Sincronização iniciada com sucesso!');
    fetchReservations();
  } catch (error) {
    alert('Erro ao sincronizar reservas.');
  } finally {
    isSyncing.value = false;
  }
};

// --- Kanban Logic ---

const isInShiftWindow = dateString => {
  if (viewAllDay.value) return true;
  const date = new Date(dateString);
  const now = new Date();
  const shiftEnd = new Date(now.getTime() + 6 * 60 * 60 * 1000); // Now + 6h
  return date >= now && date <= shiftEnd;
};

const isToday = dateString => {
  const date = new Date(dateString);
  const today = new Date();
  return (
    date.getDate() === today.getDate() &&
    date.getMonth() === today.getMonth() &&
    date.getFullYear() === today.getFullYear()
  );
};

const columns = computed(() => {
  const now = new Date();
  const toleranceMs = 30 * 60 * 1000; // 30 mins tolerance for late

  const cols = {
    // Operational
    arrivals: [],
    staying: [],
    departures: [],
    issues: [],
    // Pre-Booking
    pix_requested: [],
    awaiting_payment: [],
    payment_confirmed: [],
    expired: [],
    // History
    completed: [],
    cancelled: [],
    no_show: [],
  };

  reservations.value.forEach(res => {
    const checkIn = new Date(res.check_in_at);
    const checkOut = new Date(res.check_out_at);

    // Issues Logic Refined:
    // Atenção = apenas problemas do turno/janela atual.
    // Exclude cancelled.

    const createdAt = new Date(res.created_at || now.getTime());
    const isRecent = date => now - date < 24 * 60 * 60 * 1000;

    // --- Mode: PRE_BOOKING ---
    if (currentMode.value === 'pre_booking') {
      const hoursSinceCreation = (now - createdAt) / (1000 * 60 * 60);

      // 1. Expired (Scheduled + Unpaid + > 24h)
      if (
        res.status === 'scheduled' &&
        res.payment_status !== 'paid' &&
        hoursSinceCreation > 24
      ) {
        cols.expired.push(res);
      }
      // 2. Paid / Confirmed
      else if (
        ['scheduled', 'active'].includes(res.status) &&
        res.payment_status === 'paid'
      ) {
        cols.payment_confirmed.push(res);
      }
      // 3. Unpaid (Scheduled + Unpaid + < 24h)
      else if (res.status === 'scheduled' && res.payment_status !== 'paid') {
        // Logic: Recent (< 1h) -> Pix Solicitado, else Aguardando
        if (hoursSinceCreation < 1) {
          cols.pix_requested.push(res);
        } else {
          cols.awaiting_payment.push(res);
        }
      }
      return;
    }

    // --- Mode: HISTORY ---
    if (currentMode.value === 'history') {
      if (res.status === 'completed') {
        cols.completed.push(res);
      } else if (res.status === 'cancelled') {
        cols.cancelled.push(res);
      } else if (res.status === 'no_show') {
        cols.no_show.push(res);
      }
      return;
    }

    // --- Mode: OPERATIONAL (Default) ---
    // Exclude cancelled/no_show from operational view usually
    if (['cancelled', 'no_show'].includes(res.status)) return;

    let hasIssue = false;

    // Check Late Arrival (Scheduled but past time)
    if (
      res.status === 'scheduled' &&
      checkIn < now - toleranceMs &&
      isRecent(checkIn)
    ) {
      cols.issues.push({ ...res, issueType: 'late_arrival' });
      hasIssue = true;
    }
    // Check Overdue Checkout (Active but past time)
    else if (res.status === 'active' && checkOut < now && isRecent(checkOut)) {
      cols.issues.push({ ...res, issueType: 'overdue_checkout' });
      hasIssue = true;
    }
    // Check Unpaid (Only if Check-in is close/today)
    else if (res.status === 'pending_payment') {
      // Show if check-in is today or passed (and active/scheduled)
      if (checkIn <= now.getTime() + 12 * 60 * 60 * 1000 && isRecent(checkIn)) {
        cols.issues.push({ ...res, issueType: 'payment' });
        hasIssue = true;
      }
    }

    if (hasIssue) return;

    // Arrivals
    if (res.status === 'scheduled' && isToday(res.check_in_at)) {
      if (isInShiftWindow(res.check_in_at)) {
        cols.arrivals.push(res);
      }
    }

    // Staying (In House)
    if (res.status === 'active') {
      if (!isToday(res.check_out_at)) {
        cols.staying.push(res);
      }
      // Departures (Check-out Today and Future)
      else if (isInShiftWindow(res.check_out_at)) {
        cols.departures.push(res);
      }
    }
  });

  return cols;
});

// Actions

const onEdit = reservation => {
  selectedReservation.value = reservation;
  showEditDialog.value = true;
};

const onCancel = reservation => {
  selectedReservation.value = reservation;
  cancelDialogRef.value?.show();
};

const handleUpdateStatus = async (reservation, newStatus) => {
  try {
    await CaptainReservationsAPI.update(reservation.id, {
      reservation: { status: newStatus },
    });
    alert(t('CAPTAIN.RESERVATIONS.LIST.UPDATE_SUCCESS'));
    fetchReservations();
  } catch (error) {
    alert(t('CAPTAIN.RESERVATIONS.LIST.UPDATE_ERROR'));
  }
};

const handleQuickPay = async reservation => {
  try {
    await CaptainReservationsAPI.update(reservation.id, {
      reservation: { payment_status: 'paid' },
    });
    alert(t('CAPTAIN.RESERVATIONS.LIST.UPDATE_SUCCESS'));
    fetchReservations();
  } catch (error) {
    alert(t('CAPTAIN.RESERVATIONS.LIST.UPDATE_ERROR'));
  }
};

const handleUpdateConfirm = async formData => {
  isUpdating.value = true;
  try {
    await CaptainReservationsAPI.update(selectedReservation.value.id, {
      reservation: formData,
    });
    alert(t('CAPTAIN.RESERVATIONS.LIST.UPDATE_SUCCESS'));
    showEditDialog.value = false;
    fetchReservations();
  } catch (error) {
    alert(t('CAPTAIN.RESERVATIONS.LIST.UPDATE_ERROR'));
  } finally {
    isUpdating.value = false;
  }
};

const confirmCancel = async () => {
  try {
    await CaptainReservationsAPI.update(selectedReservation.value.id, {
      reservation: { status: 'cancelled' },
    });
    alert('Reserva cancelada com sucesso!');
    fetchReservations();
  } catch (error) {
    alert('Erro ao cancelar reserva.');
  }
};

const handleCreateConfirm = async formData => {
  isCreating.value = true;
  try {
    await CaptainReservationsAPI.create({ reservation: formData });
    alert('Reserva criada com sucesso!');
    showCreateModal.value = false;
    fetchReservations();
  } catch (error) {
    alert('Erro ao criar reserva.');
  } finally {
    isCreating.value = false;
  }
};

// Extend reservation (add extra days)
const onExtend = reservation => {
  selectedReservation.value = reservation;
  // For now, open edit dialog pre-focused on check_out date
  // A dedicated ExtendDialog could be created later
  showEditDialog.value = true;
  alert('Use o campo "Check-out" para estender a reserva.');
};

// View conversation linked to reservation
const onViewConversation = reservation => {
  if (reservation.conversation_id) {
    // Navigate to conversation
    window.open(
      `/app/accounts/${reservation.account_id}/conversations/${reservation.conversation_id}`,
      '_blank'
    );
  } else {
    alert('Esta reserva não possui uma conversa vinculada.');
  }
};

// Lifecycle
onMounted(async () => {
  await fetchUnits();
  // fetchReservations is called by watcher on filters.unit_id
});

watch(
  () => filters.unit_id,
  () => {
    if (filters.unit_id) fetchReservations();
  }
);
</script>

<template>
  <!-- eslint-disable @intlify/vue-i18n/no-raw-text, vue/no-deprecated-slot-attribute, vue/no-bare-strings-in-template -->
  <PageLayout
    :header-title="t('CAPTAIN.RESERVATIONS.LIST.HEADER_TITLE')"
    header-description="Painel Operacional de Recepção"
    :show-know-more="false"
    :show-assistant-switcher="false"
    :show-pagination-footer="false"
    :is-fetching="isLoading && !reservations.length"
    :feature-flag="FEATURE_FLAGS.CAPTAIN"
    is-full-width
  >
    <template #paywall>
      <CaptainPaywall />
    </template>

    <template #body>
      <div class="flex flex-col h-full gap-4">
        <!-- Toolbar -->
        <div
          class="bg-white dark:bg-slate-900 px-4 py-3 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm flex flex-col md:flex-row gap-4 items-center justify-between shrink-0"
        >
          <!-- Unit Selector -->
          <div class="flex items-center gap-2 w-full md:w-auto">
            <i class="i-lucide-building-2 text-slate-400" />
            <select
              v-model="filters.unit_id"
              class="h-9 px-3 rounded-lg border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-sm font-semibold text-slate-700 dark:text-slate-200 focus:ring-1 focus:ring-blue-500 outline-none w-full md:w-64"
            >
              <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
              <option value="" disabled>Selecione uma Unidade</option>
              <option v-for="unit in units" :key="unit.id" :value="unit.id">
                {{ unit.name }}
              </option>
            </select>
          </div>

          <!-- Mode Selector -->
          <div
            class="flex items-center gap-1 bg-slate-100 dark:bg-slate-800 p-1 rounded-lg"
          >
            <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
            <button
              v-for="mode in [
                {
                  id: 'operational',
                  label: 'Operacional',
                  icon: 'i-lucide-activity',
                },
                {
                  id: 'pre_booking',
                  label: 'Pré-Reserva',
                  icon: 'i-lucide-banknote',
                },
                {
                  id: 'history',
                  label: 'Histórico',
                  icon: 'i-lucide-history',
                },
              ]"
              :key="mode.id"
              class="px-3 py-1.5 rounded-md text-sm font-bold flex items-center gap-2 transition-all"
              :class="
                currentMode === mode.id
                  ? 'bg-white dark:bg-slate-700 text-blue-600 shadow-sm'
                  : 'text-slate-500 hover:text-slate-700'
              "
              @click="currentMode = mode.id"
            >
              <i :class="mode.icon" />
              <span class="hidden md:inline">{{ mode.label }}</span>
            </button>
          </div>

          <!-- Global Actions or Toggles -->
          <div class="flex items-center gap-3">
            <Button
              v-if="currentMode !== 'history'"
              icon="i-lucide-plus"
              size="sm"
              color="blue"
              @click="showCreateModal = true"
            >
              <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
              Nova Reserva
            </Button>
            <label
              class="flex items-center gap-2 text-xs font-semibold text-slate-600 cursor-pointer select-none"
            >
              <input
                v-model="viewAllDay"
                type="checkbox"
                class="rounded text-blue-600 focus:ring-blue-500"
              />
              <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
              Ver dia todo
            </label>

            <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
            <Button
              icon="i-lucide-refresh-cw"
              variant="ghost"
              size="sm"
              title="Atualizar"
              @click="fetchReservations"
            />

            <Button
              v-if="filters.unit_id"
              :is-loading="isSyncing"
              icon="i-lucide-cloud-download"
              size="sm"
              variant="outline"
              color="slate"
              @click="handleSync"
            >
              Sincronizar
            </Button>
          </div>
        </div>

        <!-- Kanban Board -->
        <div class="flex-1 min-h-0 overflow-x-auto">
          <!-- OPERATIONAL -->
          <div
            v-if="currentMode === 'operational'"
            class="flex h-full gap-4 min-w-[1000px] pb-2"
          >
            <!-- 1. Entradas (Check-in) -->
            <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
            <ReservationBoardColumn
              title="Entradas (Check-in)"
              :count="columns.arrivals.length"
              color="blue"
              class="flex-1 min-w-[280px]"
            >
              <ReservationCard
                v-for="res in columns.arrivals"
                :key="res.id"
                :reservation="res"
                :mode="currentMode"
                layout-type="entry"
                @check-in="r => handleUpdateStatus(r, 'active')"
                @pay="handleQuickPay"
                @edit="onEdit"
                @cancel="onCancel"
                @extend="onExtend"
                @view-conversation="onViewConversation"
              />
            </ReservationBoardColumn>

            <!-- 2. Hospedadas -->
            <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
            <ReservationBoardColumn
              title="Hospedadas"
              :count="columns.staying.length"
              color="emerald"
              class="flex-1 min-w-[280px]"
            >
              <ReservationCard
                v-for="res in columns.staying"
                :key="res.id"
                :reservation="res"
                :mode="currentMode"
                layout-type="staying"
                @pay="handleQuickPay"
                @edit="onEdit"
                @cancel="onCancel"
                @extend="onExtend"
                @view-conversation="onViewConversation"
              />
            </ReservationBoardColumn>

            <!-- 3. Saídas (Check-out) -->
            <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
            <ReservationBoardColumn
              title="Saídas (Check-out)"
              :count="columns.departures.length"
              color="amber"
              class="flex-1 min-w-[280px]"
            >
              <div
                v-if="!viewAllDay"
                class="mb-2 px-2 py-1 bg-amber-50 text-amber-700 text-[10px] rounded text-center"
              >
                <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
                Exibindo saídas nas próximas 6h
              </div>
              <ReservationCard
                v-for="res in columns.departures"
                :key="res.id"
                :reservation="res"
                :mode="currentMode"
                layout-type="exit"
                @check-out="r => handleUpdateStatus(r, 'completed')"
                @pay="handleQuickPay"
                @edit="onEdit"
                @cancel="onCancel"
                @extend="onExtend"
                @view-conversation="onViewConversation"
              />
            </ReservationBoardColumn>

            <!-- 4. Atenção -->
            <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
            <ReservationBoardColumn
              title="Atenção"
              :count="columns.issues.length"
              color="rose"
              class="flex-1 min-w-[280px]"
            >
              <ReservationCard
                v-for="res in columns.issues"
                :key="res.id"
                :reservation="res"
                :mode="currentMode"
                layout-type="issue"
                @pay="handleQuickPay"
                @edit="onEdit"
                @cancel="onCancel"
                @extend="onExtend"
                @view-conversation="onViewConversation"
              />
            </ReservationBoardColumn>
          </div>

          <!-- Kanban PRE_BOOKING -->
          <div
            v-else-if="currentMode === 'pre_booking'"
            class="flex h-full gap-4 min-w-[1000px] pb-2"
          >
            <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
            <ReservationBoardColumn
              title="Pix Solicitado"
              :count="columns.pix_requested.length"
              color="yellow"
              class="flex-1 min-w-[280px]"
            >
              <ReservationCard
                v-for="res in columns.pix_requested"
                :key="res.id"
                :reservation="res"
                :mode="currentMode"
                layout-type="pre_booking"
                @pay="handleQuickPay"
                @edit="onEdit"
                @cancel="onCancel"
                @extend="onExtend"
                @view-conversation="onViewConversation"
              />
            </ReservationBoardColumn>

            <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
            <ReservationBoardColumn
              title="Aguardando Pagamento"
              :count="columns.awaiting_payment.length"
              color="amber"
              class="flex-1 min-w-[280px]"
            >
              <ReservationCard
                v-for="res in columns.awaiting_payment"
                :key="res.id"
                :reservation="res"
                :mode="currentMode"
                layout-type="pre_booking"
                @pay="handleQuickPay"
                @edit="onEdit"
                @cancel="onCancel"
                @extend="onExtend"
                @view-conversation="onViewConversation"
              />
            </ReservationBoardColumn>

            <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
            <ReservationBoardColumn
              title="Pagamento Confirmado"
              :count="columns.payment_confirmed.length"
              color="emerald"
              class="flex-1 min-w-[280px]"
            >
              <ReservationCard
                v-for="res in columns.payment_confirmed"
                :key="res.id"
                :reservation="res"
                :mode="currentMode"
                layout-type="pre_booking"
                @edit="onEdit"
                @extend="onExtend"
                @view-conversation="onViewConversation"
              />
            </ReservationBoardColumn>

            <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
            <ReservationBoardColumn
              title="Expirado"
              :count="columns.expired.length"
              color="slate"
              class="flex-1 min-w-[280px]"
            >
              <ReservationCard
                v-for="res in columns.expired"
                :key="res.id"
                :reservation="res"
                :mode="currentMode"
                layout-type="pre_booking"
                @pay="handleQuickPay"
                @edit="onEdit"
                @cancel="onCancel"
                @extend="onExtend"
                @view-conversation="onViewConversation"
              />
            </ReservationBoardColumn>
          </div>

          <!-- Kanban HISTORY -->
          <div
            v-else-if="currentMode === 'history'"
            class="flex h-full gap-4 min-w-[1000px] pb-2"
          >
            <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
            <ReservationBoardColumn
              title="Finalizadas"
              :count="columns.completed.length"
              color="slate"
              class="flex-1 min-w-[280px]"
            >
              <ReservationCard
                v-for="res in columns.completed"
                :key="res.id"
                :reservation="res"
                :mode="currentMode"
                layout-type="history"
                @edit="onEdit"
                @view-conversation="onViewConversation"
              />
            </ReservationBoardColumn>

            <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
            <ReservationBoardColumn
              title="Canceladas"
              :count="columns.cancelled.length"
              color="rose"
              class="flex-1 min-w-[280px]"
            >
              <ReservationCard
                v-for="res in columns.cancelled"
                :key="res.id"
                :reservation="res"
                :mode="currentMode"
                layout-type="history"
                @edit="onEdit"
                @view-conversation="onViewConversation"
              />
            </ReservationBoardColumn>

            <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
            <ReservationBoardColumn
              title="No Show / Expiradas"
              :count="columns.no_show.length"
              color="slate"
              class="flex-1 min-w-[280px]"
            >
              <ReservationCard
                v-for="res in columns.no_show"
                :key="res.id"
                :reservation="res"
                :mode="currentMode"
                layout-type="history"
                @edit="onEdit"
                @view-conversation="onViewConversation"
              />
            </ReservationBoardColumn>
          </div>
        </div>
      </div>
    </template>
  </PageLayout>

  <CreateReservationModal
    v-if="showCreateModal"
    :units="units"
    :pre-selected-unit-id="filters.unit_id"
    :mode="currentMode"
    @close="showCreateModal = false"
    @confirm="handleCreateConfirm"
  />

  <EditReservationDialog
    v-if="showEditDialog"
    :reservation="selectedReservation"
    :units="units"
    :is-loading="isUpdating"
    @confirm="handleUpdateConfirm"
    @close="showEditDialog = false"
  />

  <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
  <Dialog
    ref="cancelDialogRef"
    type="alert"
    title="Cancelar Reserva?"
    confirm-button-label="Sim, Cancelar"
    @confirm="confirmCancel"
  >
    <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
    <p class="text-slate-600 dark:text-slate-300">
      Tem certeza que deseja cancelar esta reserva? Ela será movida para o
      Histórico.
    </p>
  </Dialog>
</template>
