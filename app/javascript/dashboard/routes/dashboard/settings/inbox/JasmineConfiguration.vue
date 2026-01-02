<script>
import { useVuelidate } from '@vuelidate/core';
import JasmineAPI from 'dashboard/api/inbox/jasmine';
import { useAlert } from 'dashboard/composables';
import JasmineKnowledgeBase from './components/JasmineKnowledgeBase.vue';

export default {
  components: {
    JasmineKnowledgeBase,
  },
  props: {
    inbox: {
      type: Object,
      required: true,
    },
    showKnowledgeBase: {
      type: Boolean,
      default: true,
    },
    isTab: {
      type: Boolean,
      default: false,
    },
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      isEnabled: false,
      systemPrompt: '',
      isUpdating: false,
    };
  },
  mounted() {
    this.fetchSettings();
  },
  methods: {
    async fetchSettings() {
      try {
        const { data } = await JasmineAPI.getSettings(this.inbox.id);
        this.isEnabled = data.is_enabled;
        this.systemPrompt = data.system_prompt || '';
      } catch (error) {
        // Assume 404 means no config yet, defaults are fine
      }
    },
    async updateSettings() {
      this.isUpdating = true;
      try {
        await JasmineAPI.updateSettings(this.inbox.id, {
          inbox_config: {
            is_enabled: this.isEnabled,
            system_prompt: this.systemPrompt,
          },
        });
        useAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(error.message || this.$t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
      } finally {
        this.isUpdating = false;
      }
    },
  },
};
</script>

<template>
  <div :class="{ 'mx-8': !isTab }">
    <div class="settings-section">
      <div class="flex flex-col gap-1 items-start mb-4">
        <h2 class="text-xl font-medium text-slate-900 dark:text-slate-100">
          Jasmine AI Configuration
        </h2>
        <p class="text-sm text-slate-600 dark:text-slate-400">
          Configure the AI agent for this inbox.
        </p>
      </div>

      <div class="mb-6">
        <label class="flex items-center gap-2 cursor-pointer">
          <input
            v-model="isEnabled"
            type="checkbox"
            class="form-checkbox h-5 w-5 text-woot-500 rounded border-gray-300 focus:ring-woot-500"
          />
          <span class="text-sm font-medium text-slate-700 dark:text-slate-200">
            Enable Jasmine AI Agent
          </span>
        </label>
      </div>

      <div class="mb-6">
        <label
          class="block text-sm font-medium text-slate-700 dark:text-slate-200 mb-2"
        >
          System Prompt
        </label>
        <textarea
          v-model="systemPrompt"
          rows="6"
          class="w-full text-sm rounded-md border-gray-300 dark:border-slate-700 dark:bg-slate-900 focus:border-woot-500 focus:ring-woot-500"
          placeholder="You are a helpful SDR agent..."
        ></textarea>
        <p class="mt-1 text-xs text-slate-500">
          Define the persona and behavioral rules for the agent.
        </p>
      </div>

      <woot-button :is-loading="isUpdating" @click="updateSettings">
        Update Configuration
      </woot-button>

      <JasmineKnowledgeBase v-if="showKnowledgeBase" :inbox-id="inbox.id" />
    </div>
  </div>
</template>
