<script setup>
import { onMounted, reactive, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import CaptainPaywall from 'dashboard/components-next/captain/pageComponents/Paywall.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

import CaptainReservationsAPI from 'dashboard/api/captain/reservations';
import CaptainUnitsAPI from 'dashboard/api/captain/units';
import EditReservationDialog from 'dashboard/components-next/captain/reservations/EditReservationDialog.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const { t } = useI18n();
const alert = useAlert();
const deleteDialogRef = ref(null);

const isLoading = ref(false);
const isFetchingUnits = ref(false);
const isUpdating = ref(false);

// Data
const reservations = ref([]);
const units = ref([]);
const selectedReservation = ref(null);
const showEditDialog = ref(false);

// Filters
const filters = reactive({
  unit_id: '',
  status: 'all',
  date_from: '',
  date_to: '',
});

// Pagination
const meta = reactive({
  page: 1,
  totalCount: 0,
});

// Options
const statusOptions = ref([
  { value: 'all', label: t('CAPTAIN.RESERVATIONS.STATUS.ALL') },
  { value: 'scheduled', label: t('CAPTAIN.RESERVATIONS.STATUS.SCHEDULED') },
  { value: 'active', label: t('CAPTAIN.RESERVATIONS.STATUS.ACTIVE') },
  {
    value: 'pending_payment',
    label: t('CAPTAIN.RESERVATIONS.STATUS.PENDING_PAYMENT'),
  },
  { value: 'cancelled', label: t('CAPTAIN.RESERVATIONS.STATUS.CANCELLED') },
  { value: 'completed', label: t('CAPTAIN.RESERVATIONS.STATUS.COMPLETED') },
]);

const fetchUnits = async () => {
  isFetchingUnits.value = true;
  try {
    const response = await CaptainUnitsAPI.get();
    units.value = response.data;
  } catch (error) {
    // console.error(error);
  } finally {
    isFetchingUnits.value = false;
  }
};

const fetchReservations = async ({ page = 1, append = false } = {}) => {
  isLoading.value = true;
  try {
    const response = await CaptainReservationsAPI.get({
      page,
      unit_id: filters.unit_id,
      status: filters.status,
      date_from: filters.date_from,
      date_to: filters.date_to,
    });

    const payload = response.data.payload || [];
    reservations.value = append ? [...reservations.value, ...payload] : payload;
    meta.page = response.data.meta?.page || page;
    meta.totalCount = response.data.meta?.total_count || 0;
  } catch (error) {
    alert(t('CAPTAIN.RESERVATIONS.ERRORS.LOAD_FAILED'));
  } finally {
    isLoading.value = false;
  }
};

const loadMore = async () => {
  if (reservations.value.length >= meta.totalCount) return;
  await fetchReservations({ page: meta.page + 1, append: true });
};

// Formatting
const formatDate = dateString => {
  if (!dateString) return '--/--/----';
  return new Date(dateString).toLocaleDateString('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
};

const formatCurrency = value => {
  if (!value) return 'R$ 0,00';
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'BRL',
  }).format(value);
};

const getStatusColor = status => {
  switch (status) {
    case 'scheduled':
      return 'bg-blue-50 text-blue-600 dark:bg-blue-900/20 dark:text-blue-300';
    case 'active':
      return 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400';
    case 'pending_payment':
      return 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400';
    case 'cancelled':
      return 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400';
    case 'completed':
      return 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-400';
    default:
      return 'bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-400';
  }
};

const getStatusLabel = status => {
  const option = statusOptions.value.find(o => o.value === status);
  return option ? option.label : status;
};

const onEdit = reservation => {
  selectedReservation.value = reservation;
  showEditDialog.value = true;
};

const onDelete = reservation => {
  selectedReservation.value = reservation;
  deleteDialogRef.value?.show();
};

const confirmDelete = async () => {
  try {
    await CaptainReservationsAPI.delete(selectedReservation.value.id);
    alert(t('CAPTAIN.RESERVATIONS.LIST.DELETE_SUCCESS'));
    fetchReservations();
  } catch (error) {
    alert(t('CAPTAIN.RESERVATIONS.LIST.DELETE_ERROR'));
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

// Lifecycle
onMounted(async () => {
  await fetchUnits();
  await fetchReservations();
});

watch(
  filters,
  () => {
    meta.page = 1;
    fetchReservations();
  },
  { deep: true }
);
</script>

<template>
  <PageLayout
    :header-title="t('CAPTAIN.RESERVATIONS.LIST.HEADER_TITLE')"
    :header-description="t('CAPTAIN.RESERVATIONS.LIST.HEADER_DESCRIPTION')"
    :show-know-more="false"
    :show-assistant-switcher="false"
    :show-pagination-footer="false"
    :is-fetching="isLoading && !reservations.length"
    :feature-flag="FEATURE_FLAGS.CAPTAIN"
  >
    <template #paywall>
      <CaptainPaywall />
    </template>

    <template #body>
      <div class="flex flex-col gap-6 h-full">
        <!-- Filters Bar -->
        <div
          class="bg-white dark:bg-slate-900 p-4 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm flex flex-col md:flex-row gap-4 items-center justify-between"
        >
          <div class="flex flex-col md:flex-row gap-3 w-full md:w-auto">
            <!-- Unit Filter -->
            <div class="w-full md:w-48">
              <label
                class="text-xs font-semibold text-slate-500 uppercase mb-1 block"
              >
                {{ t('CAPTAIN.RESERVATIONS.LIST.UNITS') }}
              </label>
              <select
                v-model="filters.unit_id"
                class="w-full h-10 px-3 rounded-lg border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-sm focus:ring-1 focus:ring-blue-500 outline-none"
              >
                <option value="">
                  {{ t('CAPTAIN.RESERVATIONS.LIST.ALL_UNITS') }}
                </option>
                <option v-for="unit in units" :key="unit.id" :value="unit.id">
                  {{ unit.name }}
                </option>
              </select>
            </div>

            <!-- Status Filter -->
            <div class="w-full md:w-40">
              <label
                class="text-xs font-semibold text-slate-500 uppercase mb-1 block"
              >
                {{ t('CAPTAIN.RESERVATIONS.LIST.TOTAL_STATUS') }}
              </label>
              <select
                v-model="filters.status"
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

            <!-- Date Filter -->
            <div class="flex gap-2">
              <div>
                <label
                  class="text-xs font-semibold text-slate-500 uppercase mb-1 block"
                >
                  {{ t('CAPTAIN.RESERVATIONS.LIST.FROM') }}
                </label>
                <input
                  v-model="filters.date_from"
                  type="date"
                  class="h-10 px-3 rounded-lg border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-sm focus:ring-1 focus:ring-blue-500 outline-none"
                />
              </div>
              <div>
                <label
                  class="text-xs font-semibold text-slate-500 uppercase mb-1 block"
                >
                  {{ t('CAPTAIN.RESERVATIONS.LIST.TO') }}
                </label>
                <input
                  v-model="filters.date_to"
                  type="date"
                  class="h-10 px-3 rounded-lg border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800 text-sm focus:ring-1 focus:ring-blue-500 outline-none"
                />
              </div>
            </div>
          </div>

          <!-- Actions -->
          <div class="flex gap-2">
            <Button
              icon="i-lucide-refresh-cw"
              variant="ghost"
              size="sm"
              @click="fetchReservations"
            />
            <!-- Add 'New Reservation' button here later if needed -->
          </div>
        </div>

        <!-- Reservations List (Hotel Card Style) -->
        <div class="flex-1 overflow-y-auto min-h-0 pr-2">
          <div
            v-if="isLoading && !reservations.length"
            class="flex justify-center py-10"
          >
            <Spinner />
          </div>

          <div
            v-else-if="reservations.length === 0"
            class="flex flex-col items-center justify-center py-20 text-slate-400"
          >
            <i class="i-lucide-calendar-x text-6xl mb-4 opacity-50" />
            <p class="text-lg font-medium">
              {{ t('CAPTAIN.RESERVATIONS.LIST.EMPTY') }}
            </p>
            <p class="text-sm">
              {{ t('CAPTAIN.RESERVATIONS.LIST.EMPTY_DESC') }}
            </p>
          </div>

          <div v-else class="grid grid-cols-1 gap-4">
            <div
              v-for="reservation in reservations"
              :key="reservation.id"
              class="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 p-5 shadow-sm hover:shadow-md transition-all group relative overflow-hidden"
            >
              <!-- Status Stripe -->
              <div
                class="absolute left-0 top-0 bottom-0 w-1.5"
                :class="getStatusColor(reservation.status).split(' ')[0]"
              />

              <div
                class="flex flex-col md:flex-row gap-6 items-start md:items-center pl-3"
              >
                <!-- Guest Info -->
                <div class="flex items-center gap-4 min-w-[200px]">
                  <Avatar
                    :src="reservation.contact?.thumbnail"
                    :name="
                      reservation.contact_name ||
                      t('CAPTAIN.RESERVATIONS.LIST.GUEST')
                    "
                    :size="48"
                  />
                  <div>
                    <h3
                      class="font-bold text-slate-800 dark:text-slate-100 text-base"
                    >
                      {{
                        reservation.contact_name ||
                        t('CAPTAIN.RESERVATIONS.LIST.GUEST')
                      }}
                    </h3>
                    <div class="flex items-center gap-1 text-xs text-slate-500">
                      <i class="i-lucide-phone size-3" />
                      {{ reservation.phone_number }}
                    </div>
                    <div class="flex items-center gap-1 text-xs text-slate-500">
                      <i class="i-lucide-hash size-3" />
                      {{
                        t('CAPTAIN.RESERVATIONS.LIST.RESERVATION_ID', {
                          id: reservation.id,
                        })
                      }}
                    </div>
                  </div>
                </div>

                <!-- Suite & Unit Info -->
                <div class="flex flex-col flex-1 gap-1">
                  <div
                    class="flex items-center gap-2 text-sm font-medium text-slate-700 dark:text-slate-200"
                  >
                    <i class="i-lucide-bed-double text-blue-500" />
                    {{
                      reservation.suite_identifier ||
                      t('CAPTAIN.RESERVATIONS.LIST.DEFAULT_SUITE')
                    }}
                  </div>
                  <div class="flex items-center gap-2 text-xs text-slate-500">
                    <i class="i-lucide-building-2" />
                    {{
                      reservation.unit?.name ||
                      t('CAPTAIN.RESERVATIONS.LIST.UNKNOWN_UNIT')
                    }}
                  </div>
                </div>

                <!-- Dates -->
                <div class="flex flex-col gap-1 min-w-[180px]">
                  <div class="text-xs text-slate-600 dark:text-slate-400">
                    {{ reservation.contact_name || '--' }}
                    <span v-if="reservation.contact_cpf">
                      {{
                        t('CAPTAIN.RESERVATIONS.LIST.CPF_FORMAT', {
                          cpf: reservation.contact_cpf,
                        })
                      }}
                    </span>
                  </div>
                  <div
                    class="flex items-center gap-2 text-sm text-slate-800 dark:text-slate-200"
                  >
                    <i class="i-lucide-calendar-arrow-down text-green-500" />
                    {{ formatDate(reservation.check_in_at) }}
                  </div>
                  <div
                    class="flex items-center gap-2 text-sm text-slate-800 dark:text-slate-200"
                  >
                    <i class="i-lucide-calendar-arrow-up text-red-400" />
                    {{ formatDate(reservation.check_out_at) }}
                  </div>
                </div>

                <!-- Price & Status -->
                <div class="flex flex-col items-end gap-2 min-w-[120px]">
                  <div
                    class="text-lg font-bold text-slate-900 dark:text-slate-100"
                  >
                    {{ formatCurrency(reservation.total_amount) }}
                  </div>
                  <!-- Payment Status Badge -->
                  <span
                    v-if="reservation.payment_status"
                    class="px-2 py-0.5 rounded-full text-xs font-semibold"
                    :class="
                      reservation.payment_status === 'paid'
                        ? 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400'
                        : 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400'
                    "
                  >
                    {{
                      reservation.payment_status === 'paid'
                        ? t('CAPTAIN.RESERVATIONS.STATUS.PAID')
                        : t('CAPTAIN.RESERVATIONS.STATUS.PENDING')
                    }}
                  </span>
                  <span
                    class="px-2.5 py-0.5 rounded-full text-xs font-bold uppercase tracking-wide"
                    :class="getStatusColor(reservation.status)"
                  >
                    {{ getStatusLabel(reservation.status) }}
                  </span>
                </div>

                <!-- Action Buttons -->
                <div
                  class="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity"
                >
                  <router-link
                    v-if="reservation.conversation_id"
                    :to="{
                      name: 'inbox_conversation',
                      params: {
                        accountId: $route.params.accountId,
                        inbox_id: reservation.inbox_id,
                        conversation_id: reservation.conversation_id,
                      },
                    }"
                    class="inline-flex items-center justify-center size-8 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800 text-slate-500 hover:text-blue-600"
                    :title="t('CAPTAIN.RESERVATIONS.LIST.VIEW_CONVERSATION')"
                  >
                    <i class="i-lucide-message-circle size-5" />
                  </router-link>
                  <Button
                    icon="i-lucide-pencil"
                    variant="ghost"
                    size="sm"
                    color="slate"
                    :title="t('CAPTAIN.RESERVATIONS.LIST.EDIT')"
                    @click="onEdit(reservation)"
                  />
                  <Button
                    icon="i-lucide-trash-2"
                    variant="ghost"
                    size="sm"
                    color="ruby"
                    :title="t('CAPTAIN.RESERVATIONS.LIST.DELETE')"
                    @click="onDelete(reservation)"
                  />
                </div>
              </div>
            </div>

            <!-- Load More -->
            <div
              v-if="reservations.length < meta.totalCount"
              class="flex justify-center py-4"
            >
              <Button
                :is-loading="isLoading"
                variant="ghost"
                :label="t('CAPTAIN.RESERVATIONS.LIST.LOAD_MORE')"
                @click="loadMore"
              />
            </div>
          </div>
        </div>
      </div>
    </template>
  </PageLayout>
  <EditReservationDialog
    v-if="showEditDialog"
    :reservation="selectedReservation"
    :units="units"
    :is-loading="isUpdating"
    @confirm="handleUpdateConfirm"
    @close="showEditDialog = false"
  />
  <Dialog
    ref="deleteDialogRef"
    type="alert"
    :title="t('CAPTAIN.RESERVATIONS.LIST.DELETE')"
    :description="
      t('CAPTAIN.RESERVATIONS.LIST.DELETE_CONFIRMATION', {
        id: selectedReservation?.id,
      })
    "
    :confirm-button-label="t('CAPTAIN.RESERVATIONS.LIST.DELETE')"
    @confirm="confirmDelete"
  />
</template>
