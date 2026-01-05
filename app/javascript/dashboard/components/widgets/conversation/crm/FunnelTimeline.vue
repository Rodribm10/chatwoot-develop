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
    class="px-4 py-4 bg-gradient-to-br from-violet-50/80 to-indigo-50/50 dark:from-violet-900/20 dark:to-indigo-900/10"
  >
    <!-- Header -->
    <div class="flex items-center justify-between mb-3">
      <div class="flex items-center gap-2">
        <span
          class="w-6 h-6 rounded-md bg-violet-100 dark:bg-violet-800/40 flex items-center justify-center"
        >
          <i
            class="i-lucide-git-branch text-sm text-violet-600 dark:text-violet-400"
          />
        </span>
        <span
          class="text-xs font-semibold text-violet-700 dark:text-violet-300 uppercase tracking-wide"
        >
          {{ $t('CONVERSATION.CRM_INSIGHTS.FUNNEL.TITLE') }}
        </span>
      </div>
      <span
        v-if="confidence"
        class="text-[10px] text-violet-600 dark:text-violet-300 bg-violet-100 dark:bg-violet-800/40 px-2 py-1 rounded-full font-medium"
      >
        {{
          $t('CONVERSATION.CRM_INSIGHTS.FUNNEL.TRUST', {
            percentage: Math.round(confidence * 100),
          })
        }}
      </span>
    </div>

    <!-- Timeline Steps -->
    <div class="flex items-center justify-between relative mb-4">
      <!-- Connecting Line -->
      <div
        class="absolute top-1/2 left-0 w-full h-0.5 bg-violet-200/50 dark:bg-violet-800/30 -translate-y-1/2"
      />

      <!-- Steps -->
      <div
        v-for="(step, index) in steps"
        :key="step.key"
        v-tooltip.top="getStepLabel(step.key)"
        class="relative z-10 flex flex-col items-center group cursor-help"
      >
        <div
          class="w-4 h-4 rounded-full border-2 transition-all duration-300 shadow-sm"
          :class="getStepClasses(step.key, index)"
        />
      </div>
    </div>

    <!-- Current Stage Info -->
    <div
      class="bg-white/70 dark:bg-violet-900/20 backdrop-blur-sm rounded-xl p-3 border border-violet-200/50 dark:border-violet-700/30 shadow-sm"
    >
      <div class="flex items-center gap-2 mb-1.5">
        <div class="w-2.5 h-2.5 rounded-full" :class="statusColorClass" />
        <span
          class="text-sm font-semibold text-violet-800 dark:text-violet-200"
        >
          {{ currentStepLabel }}
        </span>
      </div>
      <p
        v-if="reason"
        class="text-xs text-n-slate-11 dark:text-n-slate-10 leading-relaxed"
      >
        {{ reason }}
      </p>
      <div
        class="mt-2 pt-2 border-t border-violet-100 dark:border-violet-800/30 text-[10px] text-violet-400 dark:text-violet-500 italic"
      >
        {{ $t('CONVERSATION.CRM_INSIGHTS.FUNNEL.DISCLAIMER') }}
      </div>
    </div>
  </div>
</template>
