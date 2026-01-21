<script setup>
import { computed, ref, watch } from 'vue';
import { useToggle } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import Policy from 'dashboard/components/policy.vue';
import { INBOX_TYPES, getInboxIconByType } from 'dashboard/helper/inbox';

const props = defineProps({
  id: {
    type: Number,
    required: true,
  },
  inbox: {
    type: Object,
    required: true,
  },
  assistantId: {
    type: [Number, String],
    required: true,
  },
});

const emit = defineEmits(['action']);

const { t } = useI18n();
const store = useStore();

const [showActionsDropdown, toggleDropdown] = useToggle();
const isUpdating = ref(false);
const reminderToolEnabled = ref(
  props.inbox?.captain_inbox?.always_use_reminder_tool || false
);

watch(
  () => props.inbox?.captain_inbox?.always_use_reminder_tool,
  value => {
    reminderToolEnabled.value = value || false;
  }
);

const inboxName = computed(() => {
  const inbox = props.inbox;
  if (!inbox?.name) {
    return '';
  }

  const isTwilioChannel = inbox.channel_type === INBOX_TYPES.TWILIO;
  const isWhatsAppChannel = inbox.channel_type === INBOX_TYPES.WHATSAPP;
  const isEmailChannel = inbox.channel_type === INBOX_TYPES.EMAIL;

  if (isTwilioChannel || isWhatsAppChannel) {
    const identifier = inbox.messaging_service_sid || inbox.phone_number;
    return identifier ? `${inbox.name} (${identifier})` : inbox.name;
  }

  if (isEmailChannel && inbox.email) {
    return `${inbox.name} (${inbox.email})`;
  }

  return inbox.name;
});

const menuItems = computed(() => [
  {
    label: t('CAPTAIN.INBOXES.OPTIONS.EDIT'),
    value: 'edit',
    action: 'edit',
    icon: 'i-lucide-pencil-line',
  },
  {
    label: t('CAPTAIN.INBOXES.OPTIONS.DISCONNECT'),
    value: 'delete',
    action: 'delete',
    icon: 'i-lucide-trash',
  },
]);

const icon = computed(() => {
  const { medium, channel_type: type } = props.inbox;
  return getInboxIconByType(type, medium, 'outline');
});

const handleAction = ({ action, value }) => {
  toggleDropdown(false);
  emit('action', { action, value, id: props.id });
};

const unitName = ref('');

const fetchUnit = async () => {
  const unitId = props.inbox?.captain_inbox?.captain_unit_id;
  if (!unitId) return;

  try {
    const accountId = window.chatwootConfig?.account_id;
    if (!accountId) return;

    const { data } = await window.axios.get(
      `/api/v1/accounts/${accountId}/captain/units/${unitId}`
    );
    unitName.value = data.name;
  } catch (error) {
    // Ignore error
  }
};

watch(
  () => props.inbox?.captain_inbox?.captain_unit_id,
  () => {
    fetchUnit();
  },
  { immediate: true }
);

const toggleReminderTool = async value => {
  if (isUpdating.value) return;
  isUpdating.value = true;
  reminderToolEnabled.value = value;
  try {
    await store.dispatch('captainInboxes/update', {
      id: props.id,
      assistantId: props.assistantId,
      always_use_reminder_tool: value,
    });
    useAlert(t('CAPTAIN.INBOXES.REMINDER_TOOL.SUCCESS'));
  } catch (error) {
    reminderToolEnabled.value =
      props.inbox?.captain_inbox?.always_use_reminder_tool || false;
    useAlert(t('CAPTAIN.INBOXES.REMINDER_TOOL.ERROR'));
  } finally {
    isUpdating.value = false;
  }
};
</script>

<template>
  <!-- eslint-disable vue/no-bare-strings-in-template -->
  <CardLayout>
    <div class="flex justify-between w-full gap-1">
      <span
        class="text-base text-n-slate-12 line-clamp-1 flex items-center gap-2"
      >
        <span :class="icon" />
        {{ inboxName }}
      </span>
      <div class="flex items-center gap-2">
        <Policy
          v-on-clickaway="() => toggleDropdown(false)"
          :permissions="['administrator']"
          class="relative flex items-center group"
        >
          <Button
            icon="i-lucide-ellipsis-vertical"
            color="slate"
            size="xs"
            class="rounded-md group-hover:bg-n-alpha-2"
            @click="toggleDropdown()"
          />
          <DropdownMenu
            v-if="showActionsDropdown"
            :menu-items="menuItems"
            class="mt-1 ltr:right-0 rtl:left-0 top-full"
            @action="handleAction($event)"
          />
        </Policy>
      </div>
    </div>
    <div class="flex items-center justify-between mt-3 text-xs text-n-slate-11">
      <span>{{ t('CAPTAIN.INBOXES.REMINDER_TOOL.LABEL') }}</span>
      <Switch
        v-model="reminderToolEnabled"
        :disabled="isUpdating"
        @update:model-value="toggleReminderTool"
      />
    </div>
    <div v-if="unitName" class="mt-2">
      <span
        class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-slate-100 text-slate-800 dark:bg-slate-700 dark:text-slate-100"
      >
        <i class="i-lucide-building-2 mr-1 text-xs" />
        {{ unitName }}
      </span>
    </div>
    <p class="mt-1 text-xs text-n-slate-10">
      {{ t('CAPTAIN.INBOXES.REMINDER_TOOL.HELP') }}
    </p>
  </CardLayout>
</template>
