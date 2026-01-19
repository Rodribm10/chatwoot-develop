<script setup>
import { onMounted, ref } from 'vue';
import FrequentQuestionsAPI from 'dashboard/api/frequentQuestions';
import { useI18n } from 'vue-i18n';
import ReportHeader from './components/ReportHeader.vue';
import V4Button from 'dashboard/components-next/button/Button.vue';
import { useAlert } from 'dashboard/composables';

const { t } = useI18n();
const questions = ref([]);
const isLoading = ref(false);

const fetchData = async () => {
  isLoading.value = true;
  try {
    const { data } = await FrequentQuestionsAPI.get();
    questions.value = data.payload;
  } catch (error) {
    useAlert(t('REPORT.DATA_FETCHING_FAILED'));
  } finally {
    isLoading.value = false;
  }
};

onMounted(() => {
  fetchData();
});
</script>

<template>
  <div class="flex flex-col h-full bg-slate-25 dark:bg-slate-900">
    <ReportHeader :header-title="t('FREQUENT_QUESTIONS.HEADER')">
      <V4Button
        :label="t('REPORT.FILTER_ACTIONS.CLEAR_FILTER')"
        icon="i-lucide-refresh-cw"
        size="sm"
        variant="secondary"
        class="mr-2"
        @click="fetchData"
      />
    </ReportHeader>

    <div class="flex-1 overflow-auto p-6">
      <div class="max-w-6xl mx-auto">
        <header class="mb-8">
          <p class="text-slate-600 dark:text-slate-400 text-lg">
            {{ t('FREQUENT_QUESTIONS.DESCRIPTION') }}
          </p>
        </header>

        <div v-if="isLoading" class="flex items-center justify-center p-20">
          <span
            class="w-8 h-8 border-4 border-primary-200 border-t-primary-600 rounded-full animate-spin"
          />
        </div>

        <div
          v-else-if="questions.length === 0"
          class="flex flex-col items-center justify-center p-20 bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-slate-100 dark:border-slate-700"
        >
          <div class="p-4 bg-slate-50 dark:bg-slate-700 rounded-full mb-4">
            <i class="i-lucide-file-question text-3xl text-slate-400" />
          </div>
          <p class="text-slate-500 dark:text-slate-400 font-medium">
            {{ t('REPORT.FILTER_ACTIONS.EMPTY_LIST') }}
          </p>
        </div>

        <div
          v-else
          class="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-slate-100 dark:border-slate-700 overflow-hidden"
        >
          <table
            class="min-w-full divide-y divide-slate-100 dark:divide-slate-700"
          >
            <thead class="bg-slate-50/50 dark:bg-slate-800/50">
              <tr>
                <th
                  class="px-6 py-4 text-left text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider"
                >
                  {{ t('FREQUENT_QUESTIONS.QUESTION') }}
                </th>
                <th
                  class="px-6 py-4 text-right text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider w-32"
                >
                  {{ t('FREQUENT_QUESTIONS.COUNT') }}
                </th>
                <th
                  class="px-6 py-4 text-right text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider w-40"
                >
                  {{ t('FREQUENT_QUESTIONS.DATE') }}
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-100 dark:divide-slate-700">
              <tr
                v-for="q in questions"
                :key="q.id"
                class="hover:bg-slate-50/50 dark:hover:bg-slate-700/50 transition-colors"
              >
                <td class="px-6 py-5">
                  <div class="flex items-center">
                    <div
                      class="w-8 h-8 rounded bg-primary-50 dark:bg-primary-900/30 flex items-center justify-center mr-3"
                    >
                      <i
                        class="i-lucide-message-square text-primary-600 dark:text-primary-400"
                      />
                    </div>
                    <span
                      class="text-sm font-medium text-slate-900 dark:text-slate-100"
                    >
                      {{ q.question_text }}
                    </span>
                  </div>
                </td>
                <td class="px-6 py-5 text-right whitespace-nowrap">
                  <span
                    class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400"
                  >
                    {{ q.occurrence_count }}
                  </span>
                </td>
                <td
                  class="px-6 py-5 text-right whitespace-nowrap text-sm text-slate-500 dark:text-slate-400"
                >
                  {{ q.cluster_date }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</template>
