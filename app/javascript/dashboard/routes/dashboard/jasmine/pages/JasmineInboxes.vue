<script setup>
import { computed } from 'vue';
import { useRouter } from 'vue-router';
import { useStoreGetters } from 'dashboard/composables/store';

import SettingsLayout from 'dashboard/routes/dashboard/settings/SettingsLayout.vue';
import BaseSettingsHeader from 'dashboard/routes/dashboard/settings/components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const router = useRouter();
const getters = useStoreGetters();

const inboxes = computed(() => getters['inboxes/getInboxes'].value);

const openInbox = inboxId => {
  router.push({
    name: 'jasmine_inbox_dashboard',
    params: { inboxId },
  });
};

const getChannelIcon = channelType => {
  const icons = {
    'Channel::WebWidget': 'i-lucide-message-square',
    'Channel::FacebookPage': 'i-lucide-facebook',
    'Channel::TwitterProfile': 'i-lucide-twitter',
    'Channel::Whatsapp': 'i-lucide-phone',
    'Channel::Api': 'i-lucide-webhook',
    'Channel::Email': 'i-lucide-mail',
    'Channel::Telegram': 'i-lucide-send',
  };
  return icons[channelType] || 'i-lucide-inbox';
};

const getChannelName = channelType => {
  return channelType?.replace('Channel::', '') || 'Desconhecido';
};
</script>

<template>
  <SettingsLayout
    :is-loading="false"
    :no-records-found="!inboxes.length"
    no-records-message="Nenhuma caixa de entrada encontrada"
  >
    <template #header>
      <BaseSettingsHeader
        :title="$t('JASMINE.HEADER.TITLE')"
        :description="$t('JASMINE.HEADER.DESCRIPTION')"
      />
    </template>

    <template #body>
      <div class="grid gap-4 grid-cols-1 md:grid-cols-2 lg:grid-cols-3">
        <div
          v-for="inbox in inboxes"
          :key="inbox.id"
          class="flex flex-col p-6 m-[1px] outline outline-n-container outline-1 bg-n-alpha-3 rounded-md shadow cursor-pointer hover:shadow-md hover:outline-n-blue-7 transition-all"
          @click="openInbox(inbox.id)"
        >
          <!-- Icon and Status -->
          <div class="flex items-start justify-between mb-4">
            <div
              class="flex items-center justify-center size-12 rounded-lg bg-n-blue-2"
            >
              <span
                class="size-6 text-n-blue-text"
                :class="[getChannelIcon(inbox.channel_type)]"
              />
            </div>
            <span
              v-tooltip="$t('JASMINE.INBOX_LIST.ACTIVE')"
              class="text-white p-0.5 rounded-full size-5 flex items-center justify-center bg-n-teal-9"
            >
              <i class="i-ph-check-bold text-sm" />
            </span>
          </div>

          <!-- Name and Configure -->
          <div class="flex justify-between items-center mb-2">
            <span class="text-base font-semibold text-n-slate-12">{{
              inbox.name
            }}</span>
            <Button
              :label="$t('JASMINE.INBOX_LIST.CONFIGURE')"
              link
              @click.stop="openInbox(inbox.id)"
            />
          </div>

          <!-- Description -->
          <p class="text-sm text-n-slate-11">
            {{
              $t('JASMINE.INBOX_LIST.DESCRIPTION', {
                channel: getChannelName(inbox.channel_type),
              })
            }}
          </p>
        </div>
      </div>
    </template>
  </SettingsLayout>
</template>
