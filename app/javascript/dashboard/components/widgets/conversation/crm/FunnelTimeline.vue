<script>
export default {
  props: {
    funnelData: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      steps: [
        { key: 'info' },
        { key: 'price' },
        { key: 'availability' },
        { key: 'confirmation' },
        { key: 'closed' },
      ],
    };
  },
  computed: {
    stage() {
      return this.funnelData?.stage;
    },
    confidence() {
      return this.funnelData?.confidence;
    },
    reason() {
      return this.funnelData?.reason;
    },
    isClosedWon() {
      return this.stage === 'closed_won';
    },
    isClosedLost() {
      return this.stage === 'closed_lost';
    },
    currentStepKey() {
      if (this.isClosedWon || this.isClosedLost) return 'closed';
      return this.stage;
    },
    currentStepIndex() {
      return this.steps.findIndex(s => s.key === this.currentStepKey);
    },
    currentStepLabel() {
      if (this.isClosedWon) {
        return this.$t('CONVERSATION.CRM_INSIGHTS.FUNNEL.STEPS.CLOSED_WON');
      }
      if (this.isClosedLost) {
        return this.$t('CONVERSATION.CRM_INSIGHTS.FUNNEL.STEPS.CLOSED_LOST');
      }

      const stepKey = this.stage ? this.stage.toUpperCase() : '';
      return stepKey
        ? this.$t(`CONVERSATION.CRM_INSIGHTS.FUNNEL.STEPS.${stepKey}`)
        : this.stage;
    },
    statusColorClass() {
      if (this.isClosedWon) return 'bg-green-500';
      if (this.isClosedLost) return 'bg-slate-400';
      return 'bg-woot-500';
    },
  },
  methods: {
    getStepLabel(stepKey) {
      return this.$t(
        `CONVERSATION.CRM_INSIGHTS.FUNNEL.STEPS.${stepKey.toUpperCase()}`
      );
    },
    getStepClasses(stepKey, stepIndex) {
      if (stepKey === this.currentStepKey) {
        return this.getStepSpecificColor(stepKey);
      }

      if (this.currentStepIndex > stepIndex) {
        return this.getStepSpecificColor(stepKey);
      }

      // Future Steps
      return 'bg-slate-100 border-slate-200 dark:bg-slate-800 dark:border-slate-700';
    },
    getStepSpecificColor(stepKey) {
      const colors = {
        info: 'bg-blue-400 border-blue-400',
        price: 'bg-indigo-400 border-indigo-400',
        availability: 'bg-violet-400 border-violet-400',
        confirmation: 'bg-purple-400 border-purple-400',
        closed: this.isClosedWon
          ? 'bg-green-500 border-green-500'
          : 'bg-slate-400 border-slate-400',
      };
      return colors[stepKey] || 'bg-woot-500 border-woot-500';
    },
  },
};
</script>

<template>
  <div
    class="px-4 py-3 border-b border-slate-100 dark:border-slate-800 bg-green-50/50 dark:bg-green-900/10"
  >
    <div class="flex items-center justify-between mb-2">
      <span
        class="text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider"
      >
        {{ $t('CONVERSATION.CRM_INSIGHTS.FUNNEL.TITLE') }}
      </span>
      <span
        v-if="confidence"
        class="text-[10px] text-slate-400 bg-white/50 dark:bg-slate-800 px-1.5 py-0.5 rounded border border-slate-100 dark:border-slate-700"
      >
        {{
          $t('CONVERSATION.CRM_INSIGHTS.FUNNEL.TRUST', {
            percentage: Math.round(confidence * 100),
          })
        }}
      </span>
    </div>

    <!-- Timeline Steps -->
    <div class="flex items-center justify-between relative mb-3 mt-1">
      <!-- Connecting Line -->
      <div
        class="absolute top-1/2 left-0 w-full h-0.5 bg-slate-100 dark:bg-slate-800 -z-0"
      />

      <!-- Steps -->
      <div
        v-for="(step, index) in steps"
        :key="step.key"
        v-tooltip.top="getStepLabel(step.key)"
        class="relative z-10 flex flex-col items-center group cursor-help"
      >
        <div
          class="w-3 h-3 rounded-full border-2 transition-all duration-300"
          :class="getStepClasses(step.key, index)"
        />
      </div>
    </div>

    <!-- Current Stage Info -->
    <div
      class="bg-slate-50 dark:bg-slate-800/50 rounded-md p-2.5 border border-slate-100 dark:border-slate-700/50"
    >
      <div class="flex items-center gap-2 mb-1">
        <div class="w-2 h-2 rounded-full" :class="statusColorClass" />
        <span class="text-xs font-bold text-slate-700 dark:text-slate-200">
          {{ currentStepLabel }}
        </span>
      </div>
      <p
        v-if="reason"
        class="text-xs text-slate-500 dark:text-slate-400 leading-relaxed"
      >
        {{ reason }}
      </p>
      <div class="mt-2 text-[10px] text-slate-400 italic">
        {{ $t('CONVERSATION.CRM_INSIGHTS.FUNNEL.DISCLAIMER') }}
      </div>
    </div>
  </div>
</template>
