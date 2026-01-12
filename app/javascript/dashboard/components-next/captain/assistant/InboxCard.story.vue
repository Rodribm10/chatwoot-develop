<script setup>
import InboxCard from './InboxCard.vue';
import { inboxes } from 'dashboard/components-next/captain/pageComponents/emptyStates/captainEmptyStateContent.js';
</script>

<template>
  <!-- eslint-disable vue/no-bare-strings-in-template -->
  <Story
    title="Captain/Assistant/InboxCard"
    :layout="{ type: 'grid', width: '700px' }"
  >
    <Variant title="Inbox Card">
      <div
        v-for="inbox in inboxes"
        :key="inbox.id"
        class="px-20 py-4 bg-n-background"
      >
        <InboxCard :id="inbox.id" :inbox="inbox" />
      </div>
    </Variant>
  </Story>
</template>
