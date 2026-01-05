<script setup>
import { computed, ref, watch } from 'vue';
import { useWindowSize } from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useI18n } from 'vue-i18n';
import { useStore, useStoreGetters } from 'dashboard/composables/store';
import { useConversationLabels } from 'dashboard/composables/useConversationLabels';
import { formatToTitleCase } from 'dashboard/helper/commons';
import wootConstants from 'dashboard/constants/globals';
import ConversationAPI from 'dashboard/api/conversations';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import { CONVERSATION_PRIORITY } from 'shared/constants/messages';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { emitter } from 'shared/helpers/mitt';
import FunnelTimeline from './crm/FunnelTimeline.vue';

const props = defineProps({
  currentChat: {
    required: true,
    type: Object,
  },
});

const { t } = useI18n();
const { uiSettings, updateUISettings } = useUISettings();
const { width: windowWidth } = useWindowSize();
const store = useStore();
const getters = useStoreGetters();
const { accountLabels, activeLabels, onUpdateLabels } = useConversationLabels();

const isOpen = computed(() => uiSettings.value.is_crm_insights_open);
const isSmallScreen = computed(
  () => windowWidth.value < wootConstants.SMALL_SCREEN_BREAKPOINT
);

const insight = ref(null);
const latestAttempt = ref(null);
const historyEntries = ref([]);
const historyCount = ref(0);
const noDeltaMessage = ref('');
const viewMode = ref('detail');
const selectedInsightId = ref(null);
const isLoading = ref(false);
const isRefreshing = ref(false);
const errorMessage = ref('');

const formatDateTime = value => {
  if (!value) return t('CONVERSATION.CRM_INSIGHTS.NOT_AVAILABLE');
  const date = new Date(value);
  return new Intl.DateTimeFormat('pt-BR', {
    dateStyle: 'short',
    timeStyle: 'short',
  }).format(date);
};

const selectedInsight = computed(() => {
  if (selectedInsightId.value) {
    return (
      historyEntries.value.find(item => item.id === selectedInsightId.value) ||
      insight.value
    );
  }
  return insight.value;
});

const activeInsight = computed(() => selectedInsight.value || insight.value);

const normalizedHistory = computed(() => {
  const items = historyEntries.value || [];
  if (insight.value && !items.find(item => item.id === insight.value.id)) {
    return [insight.value, ...items];
  }
  return items;
});

const structuredData = computed(() => {
  const rawValue = activeInsight.value?.structured_data;
  if (!rawValue) return {};
  if (typeof rawValue === 'string') {
    try {
      return JSON.parse(rawValue);
    } catch (error) {
      return {};
    }
  }
  if (typeof rawValue === 'object') return rawValue;
  return {};
});

const summaryText = computed(
  () =>
    structuredData.value?.summary_text ||
    activeInsight.value?.summary_text ||
    ''
);
const hasInsights = computed(
  () => summaryText.value || Object.keys(structuredData.value).length > 0
);

const normalizedList = value => {
  if (!value) return [];
  if (Array.isArray(value)) return value.filter(Boolean);
  return [value].filter(Boolean);
};

const formatValue = value => {
  if (typeof value === 'string') return formatToTitleCase(value);
  if (typeof value === 'number') return value.toString();
  if (typeof value === 'boolean')
    return value ? t('GENERAL.YES') : t('GENERAL.NO');
  return String(value);
};

const preferences = computed(() => {
  const rawPreferences = structuredData.value?.preferences;
  if (!rawPreferences) return [];
  if (Array.isArray(rawPreferences)) {
    return rawPreferences.map(item => formatValue(item));
  }
  if (typeof rawPreferences === 'object') {
    return Object.entries(rawPreferences).flatMap(([key, value]) => {
      const items = normalizedList(value).map(item => formatValue(item));
      if (!items.length) return [];
      const label = formatToTitleCase(key);
      return items.map(item => `${label}: ${item}`);
    });
  }
  return [formatValue(rawPreferences)];
});

const frictions = computed(() =>
  normalizedList(structuredData.value?.frictions).map(item => formatValue(item))
);

const suggestedLabels = computed(() =>
  normalizedList(structuredData.value?.suggested_labels).map(item =>
    String(item).trim()
  )
);

const availableSuggestedLabels = computed(() => {
  const labelTitles = new Set(accountLabels.value.map(label => label.title));
  return suggestedLabels.value.filter(label => labelTitles.has(label));
});

const contactPattern = computed(
  () => structuredData.value?.contact_pattern || {}
);
const intent = computed(() => structuredData.value?.intent);
const urgency = computed(() => structuredData.value?.urgency);
const priceSensitivity = computed(
  () => structuredData.value?.price_sensitivity
);
const confidence = computed(() => structuredData.value?.confidence);
const nba = computed(() => structuredData.value?.nba || {});
const funnelData = computed(() => structuredData.value?.funnel || {});
const generatedAt = computed(() => structuredData.value?.generated_at);
const agentTip = computed(() => structuredData.value?.agent_tip);

const urgencyLabel = computed(() => {
  if (!urgency.value) return '';
  return t('CONVERSATION.CRM_INSIGHTS.URGENCY_VALUE', {
    value: urgency.value,
  });
});

const statusLabel = status => {
  const normalized = (status || 'success').toString().toLowerCase();
  const labels = {
    success: t('CONVERSATION.CRM_INSIGHTS.STATUS.SUCCESS'),
    failed: t('CONVERSATION.CRM_INSIGHTS.STATUS.FAILED'),
  };
  return labels[normalized] || labels.success;
};

const formatConfidence = value => {
  if (typeof value !== 'number') return '';
  if (value <= 1) return `${Math.round(value * 100)}%`;
  return `${Math.round(value)}%`;
};

const urgencyToPriority = value => {
  if (typeof value !== 'number') return null;
  if (value >= 5) return CONVERSATION_PRIORITY.URGENT;
  if (value >= 4) return CONVERSATION_PRIORITY.HIGH;
  if (value >= 3) return CONVERSATION_PRIORITY.MEDIUM;
  if (value >= 1) return CONVERSATION_PRIORITY.LOW;
  return null;
};

const applySuggestedLabels = async () => {
  if (!props.currentChat?.id) return;
  const currentLabels = activeLabels.value.map(label => label.title);
  const merged = Array.from(
    new Set([...currentLabels, ...availableSuggestedLabels.value])
  );
  if (!merged.length) return;
  await onUpdateLabels(merged);
};

const setPriorityFromUrgency = async () => {
  if (!props.currentChat?.id) return;
  const priority = urgencyToPriority(Number(urgency.value));
  if (!priority) return;
  await store.dispatch('assignPriority', {
    conversationId: props.currentChat.id,
    priority,
  });
};

const insertSuggestedReply = async () => {
  if (!props.currentChat?.id || !agentTip.value) return;
  emitter.emit(BUS_EVENTS.INSERT_INTO_NORMAL_EDITOR, agentTip.value);
};

const createInternalNote = async () => {
  if (!props.currentChat?.id || !summaryText.value) return;
  await store.dispatch('createPendingMessageAndSend', {
    conversationId: props.currentChat.id,
    message: summaryText.value,
    private: true,
    sender: getters.getCurrentUser?.value,
  });
};

const loadInsight = async () => {
  if (!props.currentChat?.id) return;
  isLoading.value = true;
  errorMessage.value = '';
  noDeltaMessage.value = '';
  try {
    const { data } = await ConversationAPI.getCrmInsight(props.currentChat.id);
    insight.value = data.crm_insight;
    latestAttempt.value = data.latest_attempt;
    historyEntries.value = data.history || [];
    historyCount.value = data.history_count || 0;
    if (insight.value?.id) {
      selectedInsightId.value = insight.value.id;
      viewMode.value = 'detail';
    } else {
      viewMode.value = 'list';
    }
  } catch (error) {
    errorMessage.value = t('CONVERSATION.CRM_INSIGHTS.LOAD_ERROR');
  } finally {
    isLoading.value = false;
  }
};

const refreshInsight = async () => {
  if (!props.currentChat?.id) return;
  isRefreshing.value = true;
  errorMessage.value = '';
  try {
    const { data } = await ConversationAPI.refreshCrmInsight(
      props.currentChat.id
    );
    insight.value = data.crm_insight;
    latestAttempt.value = data.latest_attempt;
    historyEntries.value = data.history || [];
    historyCount.value = data.history_count || 0;
    if (data.meta?.status === 'no_delta') {
      const formattedTime = formatDateTime(data.meta?.last_success_at);
      noDeltaMessage.value = t('CONVERSATION.CRM_INSIGHTS.NO_DELTA', {
        time: formattedTime,
      });
    } else {
      noDeltaMessage.value = '';
    }
    if (data.crm_insight?.id) {
      selectedInsightId.value = data.crm_insight.id;
      viewMode.value = 'detail';
    }
  } catch (error) {
    errorMessage.value = t('CONVERSATION.CRM_INSIGHTS.REFRESH_ERROR');
  } finally {
    isRefreshing.value = false;
  }
};

const closePanel = () => {
  updateUISettings({
    is_crm_insights_open: false,
  });
};

const goBackToList = () => {
  viewMode.value = 'list';
};

const openInsightDetail = insightId => {
  selectedInsightId.value = insightId;
  viewMode.value = 'detail';
};

const hasFailedAttempt = computed(
  () =>
    latestAttempt.value?.status === 'failed' &&
    latestAttempt.value?.generated_at
);

const failureMessage = computed(() => latestAttempt.value?.error_message);

const errorDetail = computed(() => {
  if (!failureMessage.value) return '';
  return t('CONVERSATION.CRM_INSIGHTS.ERROR_DETAIL', {
    error: failureMessage.value,
  });
});

watch(
  () => props.currentChat?.id,
  () => {
    if (isOpen.value) loadInsight();
  }
);

watch(
  () => isOpen.value,
  open => {
    if (open) loadInsight();
  }
);
</script>

<template>
  <div
    v-on-click-outside="() => (isSmallScreen ? closePanel() : null)"
    class="bg-n-background h-full overflow-hidden flex flex-col fixed top-0 z-40 w-full max-w-sm transition-transform duration-300 ease-in-out ltr:right-0 rtl:left-0 md:static md:w-[320px] md:min-w-[320px] ltr:border-l rtl:border-r border-n-weak 2xl:min-w-[360px] 2xl:w-[360px] shadow-lg md:shadow-none"
    :class="[
      {
        'md:flex': isOpen,
        'md:hidden': !isOpen,
      },
    ]"
  >
    <div
      class="flex items-center justify-between px-4 py-4 bg-gradient-to-r from-violet-50 via-indigo-50 to-violet-50 dark:from-violet-900/20 dark:via-indigo-900/20 dark:to-violet-900/20 border-b border-violet-100 dark:border-violet-800/50"
    >
      <div class="flex items-center gap-2">
        <Button
          v-if="viewMode === 'detail'"
          xs
          ghost
          slate
          icon="i-lucide-arrow-left"
          @click="goBackToList"
        />
        <span
          class="w-8 h-8 rounded-lg bg-violet-100 dark:bg-violet-800/40 flex items-center justify-center"
        >
          <i
            class="i-lucide-brain text-lg text-violet-600 dark:text-violet-400"
          />
        </span>
        <span
          class="text-sm font-semibold text-violet-900 dark:text-violet-100"
        >
          {{
            viewMode === 'detail'
              ? t('CONVERSATION.CRM_INSIGHTS.LATEST.TITLE')
              : `${t('CONVERSATION.CRM_INSIGHTS.HISTORY.TITLE')} (${historyCount})`
          }}
        </span>
      </div>
      <div class="flex items-center gap-2">
        <Button
          xs
          ghost
          slate
          :is-loading="isRefreshing"
          icon="i-lucide-refresh-cw"
          @click="refreshInsight"
        >
          {{ t('CONVERSATION.CRM_INSIGHTS.REFRESH') }}
        </Button>
        <Button xs ghost slate icon="i-lucide-x" @click="closePanel" />
      </div>
    </div>

    <div class="flex flex-col gap-4 p-4 overflow-auto">
      <div class="text-xs text-n-slate-10">
        <div>
          {{ `${t('CONVERSATION.CRM_INSIGHTS.UPDATED_AT')}:` }}
          {{
            formatDateTime(
              activeInsight?.generated_at || activeInsight?.updated_at
            )
          }}
        </div>
        <div v-if="activeInsight?.range_to_message_id">
          {{ `${t('CONVERSATION.CRM_INSIGHTS.RANGE_TO')}:` }}
          {{ activeInsight.range_to_message_id }}
        </div>
        <div>
          {{ `${t('CONVERSATION.CRM_INSIGHTS.CONTACT_SESSIONS')}:` }}
          {{ activeInsight?.contact_sessions_count ?? 0 }}
        </div>
        <div>
          {{ `${t('CONVERSATION.CRM_INSIGHTS.LAST_CONTACT')}:` }}
          {{ formatDateTime(activeInsight?.last_contact_at) }}
        </div>
      </div>

      <div v-if="isLoading" class="flex items-center justify-center py-8">
        <Spinner size="32" class="text-n-slate-10" />
      </div>

      <div v-else-if="errorMessage" class="text-sm text-n-ruby-9">
        {{ errorMessage }}
      </div>

      <div
        v-else-if="hasFailedAttempt && !hasInsights"
        class="text-sm text-n-amber-11"
      >
        {{ t('CONVERSATION.CRM_INSIGHTS.REFRESH_ERROR') }}
        <span v-if="errorDetail">{{ errorDetail }}</span>
      </div>

      <div v-else-if="viewMode === 'list'" class="flex flex-col gap-3">
        <div
          v-if="insight"
          class="rounded-2xl border border-n-weak p-4 cursor-pointer bg-n-amber-1 text-n-amber-11 shadow-sm"
          @click="openInsightDetail(insight.id)"
        >
          <div
            class="flex items-center gap-2 text-[10px] uppercase tracking-wide font-semibold"
          >
            <span class="i-lucide-pin text-base" />
            {{ t('CONVERSATION.CRM_INSIGHTS.LATEST.TITLE') }}
          </div>
          <div class="mt-2 flex items-center justify-between text-xs">
            <span>{{
              formatDateTime(insight.generated_at || insight.updated_at)
            }}</span>
            <span class="uppercase text-[10px]">
              {{ statusLabel('success') }}
            </span>
          </div>
          <div class="mt-3 text-sm">
            {{ `${t('CONVERSATION.CRM_INSIGHTS.RANGE_TO')}:` }}
            {{
              insight.range_to_message_id ||
              t('CONVERSATION.CRM_INSIGHTS.NOT_AVAILABLE')
            }}
          </div>
          <div
            v-if="insight.summary_text"
            class="mt-3 text-sm text-n-amber-12 line-clamp-3"
          >
            {{ insight.summary_text }}
          </div>
        </div>
        <div
          v-for="item in normalizedHistory.filter(
            item => item.id !== insight?.id
          )"
          :key="item.id"
          class="rounded-xl border border-n-weak p-3 cursor-pointer"
          :class="[
            item.status === 'failed'
              ? 'bg-n-ruby-1 text-n-ruby-9'
              : 'bg-n-sky-1 text-n-slate-12',
          ]"
          @click="openInsightDetail(item.id)"
        >
          <div class="flex items-center justify-between text-xs">
            <span>{{
              formatDateTime(item.generated_at || item.updated_at)
            }}</span>
            <span class="uppercase text-[10px]">
              {{ statusLabel(item.status) }}
            </span>
          </div>
          <div class="mt-2 text-sm">
            {{ `${t('CONVERSATION.CRM_INSIGHTS.RANGE_TO')}:` }}
            {{
              item.range_to_message_id ||
              t('CONVERSATION.CRM_INSIGHTS.NOT_AVAILABLE')
            }}
          </div>
          <div
            v-if="item.summary_text"
            class="mt-2 text-xs text-n-slate-10 line-clamp-2"
          >
            {{ item.summary_text }}
          </div>
          <div v-else-if="item.error_message" class="mt-2 text-xs">
            {{ item.error_message }}
          </div>
        </div>
        <div v-if="!normalizedHistory.length" class="text-sm text-n-slate-9">
          {{ t('CONVERSATION.CRM_INSIGHTS.EMPTY_STATE') }}
        </div>
      </div>

      <div v-else-if="hasInsights" class="flex flex-col gap-4">
        <div
          class="rounded-2xl border border-violet-200/50 dark:border-violet-700/30 p-4 space-y-3 bg-white/70 dark:bg-violet-900/10 backdrop-blur-sm shadow-sm"
        >
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-2">
              <span
                class="w-6 h-6 rounded-md bg-violet-100 dark:bg-violet-800/40 flex items-center justify-center"
              >
                <i
                  class="i-lucide-sparkles text-sm text-violet-600 dark:text-violet-400"
                />
              </span>
              <span
                class="text-xs font-semibold text-violet-700 dark:text-violet-300 uppercase tracking-wide"
              >
                {{ t('CONVERSATION.CRM_INSIGHTS.LATEST.TITLE') }}
              </span>
            </div>
            <span class="text-[10px] text-n-slate-10">
              {{
                formatDateTime(
                  activeInsight?.generated_at || activeInsight?.updated_at
                )
              }}
            </span>
          </div>
          <div
            v-if="summaryText"
            class="text-sm text-n-slate-12 whitespace-pre-line leading-6"
          >
            {{ summaryText }}
          </div>
          <div class="text-xs text-n-slate-10">
            {{ `${t('CONVERSATION.CRM_INSIGHTS.RANGE_TO')}:` }}
            {{
              activeInsight?.range_to_message_id ||
              t('CONVERSATION.CRM_INSIGHTS.NOT_AVAILABLE')
            }}
          </div>
        </div>

        <div
          v-if="noDeltaMessage"
          class="text-sm text-n-amber-11 border border-n-weak bg-n-amber-1 rounded-lg px-3 py-2"
        >
          {{ noDeltaMessage }}
        </div>

        <div
          v-if="hasFailedAttempt"
          class="text-xs text-n-amber-11 border border-n-weak bg-n-amber-1 rounded-lg px-3 py-2"
        >
          {{ t('CONVERSATION.CRM_INSIGHTS.REFRESH_ERROR') }}
          <span v-if="errorDetail">{{ errorDetail }}</span>
          {{ t('CONVERSATION.CRM_INSIGHTS.SEPARATOR') }}
          {{ formatDateTime(latestAttempt?.generated_at) }}
        </div>

        <div class="grid gap-3">
          <div
            v-if="funnelData?.stage"
            class="rounded-xl border border-n-weak overflow-hidden bg-n-alpha-1"
          >
            <FunnelTimeline :funnel-data="funnelData" />
          </div>

          <div
            v-if="intent"
            class="rounded-xl border border-violet-100 dark:border-violet-800/30 p-3 bg-white/50 dark:bg-violet-900/5"
          >
            <div class="flex items-center gap-2">
              <i
                class="i-lucide-target text-sm text-violet-500 dark:text-violet-400"
              />
              <span class="text-xs font-medium text-n-slate-9">
                {{ t('CONVERSATION.CRM_INSIGHTS.CARDS.INTENT') }}
              </span>
            </div>
            <div class="text-sm text-n-slate-12 mt-1">
              {{ formatValue(intent) }}
            </div>
          </div>

          <div
            v-if="urgency"
            class="rounded-xl border border-violet-100 dark:border-violet-800/30 p-3 bg-white/50 dark:bg-violet-900/5"
          >
            <div class="flex items-center gap-2">
              <i
                class="i-lucide-gauge text-sm text-violet-500 dark:text-violet-400"
              />
              <span class="text-xs font-medium text-n-slate-9">
                {{ t('CONVERSATION.CRM_INSIGHTS.CARDS.URGENCY') }}
              </span>
            </div>
            <div class="text-sm text-n-slate-12 mt-1">
              {{ urgencyLabel }}
            </div>
          </div>

          <div
            v-if="preferences.length"
            class="rounded-xl border border-violet-100 dark:border-violet-800/30 p-3 bg-white/50 dark:bg-violet-900/5"
          >
            <div class="flex items-center gap-2">
              <i
                class="i-lucide-heart text-sm text-violet-500 dark:text-violet-400"
              />
              <span class="text-xs font-medium text-n-slate-9">
                {{ t('CONVERSATION.CRM_INSIGHTS.CARDS.PREFERENCES') }}
              </span>
            </div>
            <div class="flex flex-wrap gap-2 mt-2">
              <span
                v-for="item in preferences"
                :key="item"
                class="text-xs text-violet-700 dark:text-violet-300 bg-violet-100 dark:bg-violet-900/40 px-3 py-1.5 rounded-full font-medium"
              >
                {{ item }}
              </span>
            </div>
          </div>

          <div
            v-if="priceSensitivity"
            class="rounded-xl border border-violet-100 dark:border-violet-800/30 p-3 bg-white/50 dark:bg-violet-900/5"
          >
            <div class="flex items-center gap-2">
              <i
                class="i-lucide-wallet text-sm text-violet-500 dark:text-violet-400"
              />
              <span class="text-xs font-medium text-n-slate-9">
                {{ t('CONVERSATION.CRM_INSIGHTS.CARDS.PRICE_SENSITIVITY') }}
              </span>
            </div>
            <div class="text-sm text-n-slate-12 mt-1">
              {{ formatValue(priceSensitivity) }}
            </div>
          </div>

          <div
            v-if="frictions.length"
            class="rounded-xl border border-amber-200 dark:border-amber-800/30 p-3 bg-amber-50/50 dark:bg-amber-900/5"
          >
            <div class="flex items-center gap-2">
              <i
                class="i-lucide-alert-triangle text-sm text-amber-500 dark:text-amber-400"
              />
              <span class="text-xs font-medium text-n-slate-9">
                {{ t('CONVERSATION.CRM_INSIGHTS.CARDS.FRICTIONS') }}
              </span>
            </div>
            <div class="flex flex-wrap gap-2 mt-2">
              <span
                v-for="item in frictions"
                :key="item"
                class="text-xs text-amber-700 dark:text-amber-300 bg-amber-100 dark:bg-amber-900/40 px-3 py-1.5 rounded-full font-medium"
              >
                {{ item }}
              </span>
            </div>
          </div>

          <div
            v-if="contactPattern.time_range || contactPattern.days?.length"
            class="rounded-xl border border-n-weak p-3"
          >
            <div class="text-xs font-medium text-n-slate-9">
              {{ t('CONVERSATION.CRM_INSIGHTS.CARDS.CONTACT_PATTERN') }}
            </div>
            <div class="text-sm text-n-slate-12">
              <div v-if="contactPattern.time_range">
                {{ t('CONVERSATION.CRM_INSIGHTS.CARDS.CONTACT_TIME_LABEL') }}
                {{ contactPattern.time_range }}
              </div>
              <div v-if="contactPattern.days?.length">
                {{ t('CONVERSATION.CRM_INSIGHTS.CARDS.CONTACT_DAYS_LABEL') }}
                {{
                  contactPattern.days.map(day => formatValue(day)).join(', ')
                }}
              </div>
            </div>
          </div>

          <div
            v-if="nba?.action || nba?.reason"
            class="rounded-xl border border-n-weak p-3"
          >
            <div class="text-xs font-medium text-n-slate-9">
              {{ t('CONVERSATION.CRM_INSIGHTS.CARDS.NBA') }}
            </div>
            <div class="text-sm text-n-slate-12 space-y-1 mt-2">
              <div v-if="nba.action">
                <span class="font-semibold">
                  {{ t('CONVERSATION.CRM_INSIGHTS.CARDS.NBA_ACTION_LABEL') }}
                </span>
                <span>{{ formatValue(nba.action) }}</span>
              </div>
              <div v-if="nba.priority">
                <span class="font-semibold">
                  {{ t('CONVERSATION.CRM_INSIGHTS.CARDS.NBA_PRIORITY_LABEL') }}
                </span>
                <span>{{ formatValue(nba.priority) }}</span>
              </div>
              <div v-if="nba.reason">
                <span class="font-semibold">
                  {{ t('CONVERSATION.CRM_INSIGHTS.CARDS.NBA_REASON_LABEL') }}
                </span>
                <span>{{ nba.reason }}</span>
              </div>
            </div>
          </div>

          <div
            v-if="suggestedLabels.length"
            class="rounded-xl border border-n-weak p-3"
          >
            <div class="text-xs font-medium text-n-slate-9">
              {{ t('CONVERSATION.CRM_INSIGHTS.CARDS.SUGGESTED_LABELS') }}
            </div>
            <div class="flex flex-wrap gap-2 mt-2">
              <span
                v-for="item in suggestedLabels"
                :key="item"
                class="text-xs text-n-slate-12 bg-n-strong px-2 py-1 rounded-full"
              >
                {{ item }}
              </span>
            </div>
            <div class="mt-3">
              <Button
                xs
                outline
                slate
                :disabled="!availableSuggestedLabels.length"
                icon="i-lucide-tag"
                @click="applySuggestedLabels"
              >
                {{ t('CONVERSATION.CRM_INSIGHTS.ACTIONS.APPLY_LABELS') }}
              </Button>
            </div>
          </div>

          <div v-if="confidence" class="rounded-xl border border-n-weak p-3">
            <div class="text-xs font-medium text-n-slate-9">
              {{ t('CONVERSATION.CRM_INSIGHTS.CARDS.CONFIDENCE') }}
            </div>
            <div class="text-sm text-n-slate-12">
              {{ formatConfidence(confidence) }}
            </div>
          </div>

          <div v-if="generatedAt" class="rounded-xl border border-n-weak p-3">
            <div class="text-xs font-medium text-n-slate-9">
              {{ t('CONVERSATION.CRM_INSIGHTS.CARDS.GENERATED_AT') }}
            </div>
            <div class="text-sm text-n-slate-12">
              {{ formatDateTime(generatedAt) }}
            </div>
          </div>
        </div>

        <div class="rounded-xl border border-n-weak p-3">
          <div class="text-xs font-medium text-n-slate-9">
            {{ t('CONVERSATION.CRM_INSIGHTS.ACTIONS.TITLE') }}
          </div>
          <div class="flex flex-wrap gap-2 mt-3">
            <Button
              xs
              outline
              slate
              icon="i-lucide-alert-triangle"
              :disabled="!urgency"
              @click="setPriorityFromUrgency"
            >
              {{ t('CONVERSATION.CRM_INSIGHTS.ACTIONS.SET_PRIORITY') }}
            </Button>
            <Button
              xs
              outline
              slate
              icon="i-lucide-message-square"
              :disabled="!agentTip"
              @click="insertSuggestedReply"
            >
              {{ t('CONVERSATION.CRM_INSIGHTS.ACTIONS.INSERT_REPLY') }}
            </Button>
            <Button
              xs
              outline
              slate
              icon="i-lucide-sticky-note"
              :disabled="!summaryText"
              @click="createInternalNote"
            >
              {{ t('CONVERSATION.CRM_INSIGHTS.ACTIONS.CREATE_NOTE') }}
            </Button>
          </div>
        </div>

        <div
          v-if="historyCount > 1"
          class="rounded-xl border border-n-weak p-3"
        >
          <div class="flex items-center justify-between">
            <div class="text-xs font-medium text-n-slate-9">
              {{
                `${t('CONVERSATION.CRM_INSIGHTS.HISTORY.TITLE')} (${historyCount})`
              }}
            </div>
            <Button
              xs
              ghost
              slate
              icon="i-lucide-list"
              @click="viewMode = 'list'"
            >
              {{ t('CONVERSATION.CRM_INSIGHTS.HISTORY.SHOW') }}
            </Button>
          </div>
        </div>
      </div>

      <div v-else class="text-sm text-n-slate-9">
        {{ t('CONVERSATION.CRM_INSIGHTS.EMPTY_STATE') }}
      </div>
    </div>
  </div>
</template>
