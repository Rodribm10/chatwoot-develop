<script setup>
/* eslint-disable @intlify/vue-i18n/no-raw-text, vue/no-bare-strings-in-template */
defineProps({
  title: {
    type: String,
    required: true,
  },
  count: {
    type: Number,
    default: 0,
  },
  color: {
    type: String,
    default: 'blue', // blue, emerald, amber, rose
  },
});
</script>

<template>
  <!-- eslint-disable @intlify/vue-i18n/no-raw-text, vue/no-bare-strings-in-template -->
  <div
    class="flex flex-col h-full bg-slate-50 dark:bg-slate-900/50 rounded-xl border border-slate-200 dark:border-slate-800 overflow-hidden"
  >
    <!-- Header -->
    <div
      class="px-4 py-3 border-b border-slate-200 dark:border-slate-800 flex justify-between items-center bg-white dark:bg-slate-900"
      :class="{
        'border-t-4 border-t-blue-500': color === 'blue',
        'border-t-4 border-t-emerald-500': color === 'emerald',
        'border-t-4 border-t-amber-500': color === 'amber',
        'border-t-4 border-t-rose-500': color === 'rose',
        'border-t-4 border-t-slate-500': color === 'slate',
      }"
    >
      <div class="flex items-center gap-2">
        <h3
          class="font-bold text-slate-800 dark:text-slate-100 uppercase text-xs tracking-wider"
        >
          {{ title }}
        </h3>
        <span
          class="bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400 text-[10px] font-bold px-2 py-0.5 rounded-full"
        >
          {{ count }}
        </span>
      </div>

      <!-- Optional Header Actions (like Toggles) -->
      <div>
        <slot name="header-actions" />
      </div>
    </div>

    <!-- Body (Scrollable) -->
    <div class="flex-1 overflow-y-auto p-3 space-y-3 min-h-0 custom-scrollbar">
      <slot />

      <div
        v-if="count === 0"
        class="flex flex-col items-center justify-center py-10 text-slate-400 opacity-60"
      >
        <i class="i-lucide-inbox text-2xl mb-2" />
        <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
        <span class="text-xs font-medium">Vazio</span>
      </div>
    </div>
  </div>
</template>

<style scoped>
.custom-scrollbar::-webkit-scrollbar {
  width: 4px;
}
.custom-scrollbar::-webkit-scrollbar-track {
  background: transparent;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
  background-color: rgba(156, 163, 175, 0.3);
  border-radius: 4px;
}
</style>
