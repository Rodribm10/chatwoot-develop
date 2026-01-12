<script setup>
import { onMounted, ref } from 'vue';
import { useAlert } from 'dashboard/composables';
import { useRoute } from 'vue-router';
import SettingsLayout from '../../settings/SettingsLayout.vue';
import BaseSettingsHeader from '../../settings/components/BaseSettingsHeader.vue';

const reminders = ref([]);
const isLoading = ref(false);
const route = useRoute();
const accountId = route.params.accountId;

const fetchReminders = async () => {
  isLoading.value = true;
  try {
    const { data } = await window.axios.get(
      `/api/v1/accounts/${accountId}/captain/reminders`
    );
    reminders.value = data;
  } catch (error) {
    useAlert('Erro ao buscar lembretes');
  } finally {
    isLoading.value = false;
  }
};

onMounted(fetchReminders);
</script>

<template>
  <!-- eslint-disable vue/no-bare-strings-in-template -->
  <SettingsLayout>
    <BaseSettingsHeader
      title="Fila de Lembretes"
      description="Veja as mensagens agendadas e enviadas pelo sistema."
    />

    <div class="flex flex-col gap-4 p-8">
      <div v-if="isLoading" class="text-center">
        <span class="spinner" />
      </div>

      <div v-else class="flex flex-col gap-4">
        <div class="overflow-x-auto border rounded-md">
          <table
            class="min-w-full divide-y divide-gray-200 dark:divide-gray-700"
          >
            <thead class="bg-gray-50 dark:bg-gray-800">
              <tr>
                <th
                  class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                >
                  Agendamento
                </th>
                <th
                  class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                >
                  Contato
                </th>
                <th
                  class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                >
                  Status
                </th>
                <th
                  class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                >
                  Mensagem
                </th>
              </tr>
            </thead>
            <tbody
              class="bg-white divide-y divide-gray-200 dark:bg-gray-900 dark:divide-gray-700"
            >
              <tr v-for="reminder in reminders" :key="reminder.id">
                <td
                  class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 dark:text-white"
                >
                  {{ new Date(reminder.scheduled_at).toLocaleString() }}
                </td>
                <td
                  class="px-6 py-4 whitespace-nowrap text-sm text-gray-500 dark:text-gray-300"
                >
                  {{ reminder.contact_name || '-' }}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm">
                  <span
                    class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full"
                    :class="{
                      'bg-yellow-100 text-yellow-800':
                        reminder.status === 'pending',
                      'bg-green-100 text-green-800': reminder.status === 'sent',
                      'bg-red-100 text-red-800': reminder.status === 'failed',
                    }"
                  >
                    {{ reminder.status }}
                  </span>
                </td>
                <td
                  class="px-6 py-4 text-sm text-gray-500 dark:text-gray-300 truncate max-w-xs"
                >
                  {{ reminder.message }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div
          v-if="reminders.length === 0"
          class="text-center text-slate-500 p-4"
        >
          Nenhum lembrete na fila.
        </div>
      </div>
    </div>
  </SettingsLayout>
</template>
