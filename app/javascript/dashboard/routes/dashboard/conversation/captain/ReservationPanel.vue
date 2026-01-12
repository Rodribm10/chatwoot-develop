<script setup>
import { computed, onMounted, reactive, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import SelectMenu from 'dashboard/components-next/selectmenu/SelectMenu.vue';
import CaptainReservationsAPI from 'dashboard/api/captain/reservations';
import CaptainRemindersAPI from 'dashboard/api/captain/reminders';
import CaptainInboxAutomationsAPI from 'dashboard/api/captain/inboxAutomations';
import CaptainUnitsAPI from 'dashboard/api/captain/units';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
  inboxId: {
    type: Number,
    default: undefined,
  },
});

const { t } = useI18n();

const reservations = ref([]);
const reminders = ref([]);
const automations = ref([]);
const units = ref([]);

const automationForm = reactive({
  title: '',
  message: '',
  trigger_event: 'check_in',
  timing: 'after',
  offset_minutes: 15,
});

const editingAutomationId = ref(null);
const editingAutomationForm = reactive({
  title: '',
  message: '',
  trigger_event: 'check_in',
  timing: 'after',
  offset_minutes: 15,
});

const reservationForm = reactive({
  captain_unit_id: null,
  suite_identifier: '',
  check_in_at: '',
  duration_hours: 3,
  total_amount: null,
});

const reminderForm = reactive({
  message: '',
  scheduled_at: '',
});

const isLoading = ref(false);

const triggerOptions = [
  {
    value: 'check_in',
    label: t('CAPTAIN.RESERVATIONS.AUTOMATIONS.TRIGGER_CHECK_IN'),
  },
  {
    value: 'check_out',
    label: t('CAPTAIN.RESERVATIONS.AUTOMATIONS.TRIGGER_CHECK_OUT'),
  },
];

const timingOptions = [
  {
    value: 'before',
    label: t('CAPTAIN.RESERVATIONS.AUTOMATIONS.TIMING_BEFORE'),
  },
  { value: 'after', label: t('CAPTAIN.RESERVATIONS.AUTOMATIONS.TIMING_AFTER') },
];

const getTriggerLabel = value =>
  triggerOptions.find(option => option.value === value)?.label ||
  t('CAPTAIN.RESERVATIONS.AUTOMATIONS.FORM.TRIGGER');

const getTimingLabel = value =>
  timingOptions.find(option => option.value === value)?.label ||
  t('CAPTAIN.RESERVATIONS.AUTOMATIONS.FORM.TIMING');

const checkOutPreview = computed(() => {
  if (!reservationForm.check_in_at || !reservationForm.duration_hours)
    return '';
  const checkIn = new Date(reservationForm.check_in_at);
  if (Number.isNaN(checkIn.getTime())) return '';
  const checkOut = new Date(
    checkIn.getTime() + reservationForm.duration_hours * 60 * 60 * 1000
  );
  return checkOut.toISOString();
});

const loadData = async () => {
  if (!props.conversationId) return;
  isLoading.value = true;
  try {
    const [reservationsResponse, remindersResponse] = await Promise.all([
      CaptainReservationsAPI.get({
        conversationId: props.conversationId,
      }),
      CaptainRemindersAPI.get({
        conversationId: props.conversationId,
      }),
    ]);
    reservations.value = reservationsResponse.data.payload || [];
    reminders.value = remindersResponse.data.payload || [];
  } catch (error) {
    useAlert(t('CAPTAIN.RESERVATIONS.ERRORS.LOAD_FAILED'));
  } finally {
    isLoading.value = false;
  }
};

const loadAutomations = async () => {
  if (!props.inboxId) return;
  try {
    const response = await CaptainInboxAutomationsAPI.get({
      inboxId: props.inboxId,
    });
    automations.value = response.data.payload || [];
  } catch (error) {
    useAlert(t('CAPTAIN.RESERVATIONS.AUTOMATIONS.ERRORS.LOAD_FAILED'));
  }
};

const createAutomation = async () => {
  if (!props.inboxId) return;
  if (!automationForm.title || !automationForm.message) {
    useAlert(t('CAPTAIN.RESERVATIONS.AUTOMATIONS.ERRORS.MISSING_FIELDS'));
    return;
  }

  try {
    await CaptainInboxAutomationsAPI.create({
      automation: {
        inbox_id: props.inboxId,
        title: automationForm.title,
        message: automationForm.message,
        trigger_event: automationForm.trigger_event,
        timing: automationForm.timing,
        offset_minutes: Number(automationForm.offset_minutes) || 0,
      },
    });
    useAlert(t('CAPTAIN.RESERVATIONS.AUTOMATIONS.SUCCESS.CREATED'));
    automationForm.title = '';
    automationForm.message = '';
    automationForm.trigger_event = 'check_in';
    automationForm.timing = 'after';
    automationForm.offset_minutes = 15;
    await loadAutomations();
  } catch (error) {
    useAlert(t('CAPTAIN.RESERVATIONS.AUTOMATIONS.ERRORS.CREATE_FAILED'));
  }
};

const startEditAutomation = automation => {
  editingAutomationId.value = automation.id;
  editingAutomationForm.title = automation.title;
  editingAutomationForm.message = automation.message;
  editingAutomationForm.trigger_event = automation.trigger_event;
  editingAutomationForm.timing = automation.timing;
  editingAutomationForm.offset_minutes = automation.offset_minutes;
};

const cancelEditAutomation = () => {
  editingAutomationId.value = null;
};

const updateAutomation = async automation => {
  try {
    await CaptainInboxAutomationsAPI.update(automation.id, {
      automation: {
        title: editingAutomationForm.title,
        message: editingAutomationForm.message,
        trigger_event: editingAutomationForm.trigger_event,
        timing: editingAutomationForm.timing,
        offset_minutes: Number(editingAutomationForm.offset_minutes) || 0,
      },
    });
    useAlert(t('CAPTAIN.RESERVATIONS.AUTOMATIONS.SUCCESS.UPDATED'));
    editingAutomationId.value = null;
    await loadAutomations();
  } catch (error) {
    useAlert(t('CAPTAIN.RESERVATIONS.AUTOMATIONS.ERRORS.UPDATE_FAILED'));
  }
};

const deleteAutomation = async automation => {
  try {
    await CaptainInboxAutomationsAPI.delete(automation.id);
    useAlert(t('CAPTAIN.RESERVATIONS.AUTOMATIONS.SUCCESS.DELETED'));
    await loadAutomations();
  } catch (error) {
    useAlert(t('CAPTAIN.RESERVATIONS.AUTOMATIONS.ERRORS.DELETE_FAILED'));
  }
};

const createReservation = async () => {
  if (!reservationForm.check_in_at || !reservationForm.duration_hours) {
    useAlert(t('CAPTAIN.RESERVATIONS.ERRORS.MISSING_RESERVATION_FIELDS'));
    return;
  }

  try {
    await CaptainReservationsAPI.create({
      reservation: {
        conversation_id: props.conversationId,
        captain_unit_id: reservationForm.captain_unit_id,
        suite_identifier: reservationForm.suite_identifier,
        check_in_at: reservationForm.check_in_at,
        duration_minutes: Number(reservationForm.duration_hours) * 60,
        total_amount: reservationForm.total_amount,
      },
    });
    useAlert(t('CAPTAIN.RESERVATIONS.SUCCESS.CREATED'));
    reservationForm.suite_identifier = '';
    reservationForm.check_in_at = '';
    reservationForm.duration_hours = 3;
    reservationForm.total_amount = null;
    await loadData();
  } catch (error) {
    useAlert(t('CAPTAIN.RESERVATIONS.ERRORS.CREATE_FAILED'));
  }
};

const createReminder = async () => {
  if (!reminderForm.message || !reminderForm.scheduled_at) {
    useAlert(t('CAPTAIN.REMINDERS.ERRORS.MISSING_FIELDS'));
    return;
  }

  try {
    await CaptainRemindersAPI.create({
      reminder: {
        conversation_id: props.conversationId,
        message: reminderForm.message,
        scheduled_at: reminderForm.scheduled_at,
        reminder_type: 'manual',
      },
    });
    useAlert(t('CAPTAIN.REMINDERS.SUCCESS.CREATED'));
    reminderForm.message = '';
    reminderForm.scheduled_at = '';
    await loadData();
  } catch (error) {
    useAlert(t('CAPTAIN.REMINDERS.ERRORS.CREATE_FAILED'));
  }
};

const cancelReminder = async reminder => {
  try {
    await CaptainRemindersAPI.delete(reminder.id);
    useAlert(t('CAPTAIN.REMINDERS.SUCCESS.CANCELLED'));
    await loadData();
  } catch (error) {
    useAlert(t('CAPTAIN.REMINDERS.ERRORS.CANCEL_FAILED'));
  }
};

const loadUnits = async () => {
  try {
    const response = await CaptainUnitsAPI.get();
    units.value = response.data || [];
  } catch (error) {
    // Silent fail
  }
};

onMounted(async () => {
  await Promise.all([loadData(), loadAutomations(), loadUnits()]);
});

watch(
  () => props.inboxId,
  async inboxId => {
    if (!inboxId) return;
    await loadAutomations();
  }
);
</script>

<template>
  <div class="flex flex-col gap-4">
    <div class="flex flex-col gap-2">
      <h4 class="text-sm font-semibold text-n-slate-12">
        {{ t('CAPTAIN.RESERVATIONS.SECTION_TITLE') }}
      </h4>
      <div v-if="units.length > 0">
        <label class="block text-xs font-semibold text-n-slate-12 mb-1">
          {{ t('CAPTAIN.RESERVATIONS.FORM.UNIT_LABEL') }}
        </label>
        <select
          v-model="reservationForm.captain_unit_id"
          class="w-full rounded-md border-n-weak text-sm py-1.5 px-3 bg-slate-25 dark:bg-slate-900 border text-slate-900 dark:text-slate-100 placeholder-slate-400 dark:placeholder-slate-400 focus:outline-none focus:ring-1 focus:ring-woot-500 focus:border-woot-500"
        >
          <option :value="null" disabled>
            {{ t('CAPTAIN.RESERVATIONS.FORM.UNIT_PLACEHOLDER') }}
          </option>
          <option v-for="unit in units" :key="unit.id" :value="unit.id">
            {{ unit.name }}
          </option>
        </select>
      </div>
      <Input
        v-model="reservationForm.suite_identifier"
        :label="t('CAPTAIN.RESERVATIONS.FORM.SUITE_LABEL')"
        :placeholder="t('CAPTAIN.RESERVATIONS.FORM.SUITE_PLACEHOLDER')"
      />
      <Input
        v-model="reservationForm.check_in_at"
        type="datetime-local"
        :label="t('CAPTAIN.RESERVATIONS.FORM.CHECK_IN_LABEL')"
      />
      <Input
        v-model.number="reservationForm.duration_hours"
        type="number"
        min="1"
        :label="t('CAPTAIN.RESERVATIONS.FORM.DURATION_LABEL')"
      />
      <Input
        v-model="reservationForm.total_amount"
        type="number"
        step="0.01"
        :label="t('CAPTAIN.RESERVATIONS.FORM.TOTAL_AMOUNT_LABEL')"
      />
      <p v-if="checkOutPreview" class="text-xs text-n-slate-11">
        {{ t('CAPTAIN.RESERVATIONS.FORM.CHECK_OUT_PREVIEW') }}:
        {{ checkOutPreview }}
      </p>
      <Button
        size="sm"
        :label="t('CAPTAIN.RESERVATIONS.FORM.SUBMIT')"
        @click="createReservation"
      />
    </div>

    <div class="flex flex-col gap-2">
      <h4 class="text-sm font-semibold text-n-slate-12">
        {{ t('CAPTAIN.REMINDERS.SECTION_TITLE') }}
      </h4>
      <TextArea
        v-model="reminderForm.message"
        :label="t('CAPTAIN.REMINDERS.FORM.MESSAGE_LABEL')"
        :placeholder="t('CAPTAIN.REMINDERS.FORM.MESSAGE_PLACEHOLDER')"
        :rows="3"
      />
      <Input
        v-model="reminderForm.scheduled_at"
        type="datetime-local"
        :label="t('CAPTAIN.REMINDERS.FORM.TIME_LABEL')"
      />
      <Button
        size="sm"
        :label="t('CAPTAIN.REMINDERS.FORM.SUBMIT')"
        @click="createReminder"
      />
    </div>

    <div class="flex flex-col gap-2">
      <h4 class="text-sm font-semibold text-n-slate-12">
        {{ t('CAPTAIN.RESERVATIONS.AUTOMATIONS.TITLE') }}
      </h4>
      <Input
        v-model="automationForm.title"
        :label="t('CAPTAIN.RESERVATIONS.AUTOMATIONS.FORM.TITLE')"
      />
      <TextArea
        v-model="automationForm.message"
        :label="t('CAPTAIN.RESERVATIONS.AUTOMATIONS.FORM.MESSAGE')"
        :rows="2"
      />
      <div class="flex items-center gap-2">
        <SelectMenu
          v-model="automationForm.trigger_event"
          :label="getTriggerLabel(automationForm.trigger_event)"
          :options="triggerOptions"
          sub-menu-position="bottom"
        />
        <SelectMenu
          v-model="automationForm.timing"
          :label="getTimingLabel(automationForm.timing)"
          :options="timingOptions"
          sub-menu-position="bottom"
        />
        <Input
          v-model.number="automationForm.offset_minutes"
          type="number"
          min="0"
          :label="t('CAPTAIN.RESERVATIONS.AUTOMATIONS.FORM.MINUTES')"
        />
      </div>
      <Button
        size="sm"
        variant="faded"
        color="slate"
        :label="t('CAPTAIN.RESERVATIONS.AUTOMATIONS.FORM.SUBMIT')"
        @click="createAutomation"
      />
      <div v-if="automations.length" class="flex flex-col gap-2">
        <h5 class="text-xs font-semibold text-n-slate-11">
          {{ t('CAPTAIN.RESERVATIONS.AUTOMATIONS.LIST_TITLE') }}
        </h5>
        <div
          v-for="automation in automations"
          :key="automation.id"
          class="rounded-md border border-n-weak p-2 text-xs text-n-slate-11"
        >
          <template v-if="editingAutomationId === automation.id">
            <Input
              v-model="editingAutomationForm.title"
              :label="t('CAPTAIN.RESERVATIONS.AUTOMATIONS.FORM.TITLE')"
            />
            <TextArea
              v-model="editingAutomationForm.message"
              :label="t('CAPTAIN.RESERVATIONS.AUTOMATIONS.FORM.MESSAGE')"
              :rows="2"
            />
            <div class="flex items-center gap-2">
              <SelectMenu
                v-model="editingAutomationForm.trigger_event"
                :label="getTriggerLabel(editingAutomationForm.trigger_event)"
                :options="triggerOptions"
                sub-menu-position="bottom"
              />
              <SelectMenu
                v-model="editingAutomationForm.timing"
                :label="getTimingLabel(editingAutomationForm.timing)"
                :options="timingOptions"
                sub-menu-position="bottom"
              />
              <Input
                v-model.number="editingAutomationForm.offset_minutes"
                type="number"
                min="0"
                :label="t('CAPTAIN.RESERVATIONS.AUTOMATIONS.FORM.MINUTES')"
              />
            </div>
            <div class="flex items-center gap-2">
              <Button
                size="sm"
                variant="faded"
                color="slate"
                :label="t('CAPTAIN.RESERVATIONS.AUTOMATIONS.FORM.UPDATE')"
                @click="updateAutomation(automation)"
              />
              <Button
                size="sm"
                variant="ghost"
                color="slate"
                :label="t('CAPTAIN.RESERVATIONS.AUTOMATIONS.FORM.CANCEL')"
                @click="cancelEditAutomation"
              />
            </div>
          </template>
          <template v-else>
            <div class="font-semibold">{{ automation.title }}</div>
            <div>{{ automation.message }}</div>
            <div class="uppercase">
              {{ getTriggerLabel(automation.trigger_event) }} ·
              {{ getTimingLabel(automation.timing) }} ·
              <!-- eslint-disable-next-line vue/no-bare-strings-in-template -->
              {{ automation.offset_minutes }}m
            </div>
            <div class="flex items-center gap-2">
              <Button
                size="sm"
                variant="ghost"
                color="slate"
                :label="t('CAPTAIN.RESERVATIONS.AUTOMATIONS.EDIT')"
                @click="startEditAutomation(automation)"
              />
              <Button
                size="sm"
                variant="ghost"
                color="slate"
                :label="t('CAPTAIN.RESERVATIONS.AUTOMATIONS.DELETE')"
                @click="deleteAutomation(automation)"
              />
            </div>
          </template>
        </div>
      </div>
      <p v-else class="text-xs text-n-slate-11">
        {{ t('CAPTAIN.RESERVATIONS.AUTOMATIONS.EMPTY') }}
      </p>
    </div>

    <div v-if="reservations.length" class="flex flex-col gap-2">
      <h4 class="text-sm font-semibold text-n-slate-12">
        {{ t('CAPTAIN.RESERVATIONS.LIST_TITLE') }}
      </h4>
      <div
        v-for="reservation in reservations"
        :key="reservation.id"
        class="rounded-md border border-n-weak p-2 text-xs text-n-slate-11"
      >
        <div>
          {{
            reservation.suite_identifier || t('CAPTAIN.RESERVATIONS.NO_SUITE')
          }}
        </div>
        <div>{{ reservation.check_in_at }}</div>
        <div>{{ reservation.check_out_at }}</div>
        <div class="uppercase">{{ reservation.status }}</div>
      </div>
    </div>

    <div v-if="reminders.length" class="flex flex-col gap-2">
      <h4 class="text-sm font-semibold text-n-slate-12">
        {{ t('CAPTAIN.REMINDERS.LIST_TITLE') }}
      </h4>
      <div
        v-for="reminder in reminders"
        :key="reminder.id"
        class="rounded-md border border-n-weak p-2 text-xs text-n-slate-11"
      >
        <div>{{ reminder.message }}</div>
        <div>{{ reminder.scheduled_at }}</div>
        <div class="flex items-center justify-between">
          <span class="uppercase">{{ reminder.status }}</span>
          <Button
            v-if="reminder.status === 'scheduled'"
            size="sm"
            variant="ghost"
            color="slate"
            icon="i-lucide-x"
            @click="cancelReminder(reminder)"
          />
        </div>
      </div>
    </div>
  </div>
</template>
