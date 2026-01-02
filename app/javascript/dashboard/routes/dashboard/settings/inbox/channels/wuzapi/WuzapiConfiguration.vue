<script>
// Use global axios (window.axios) which has interceptors for auth headers
import { defineComponent, ref, onMounted, onUnmounted, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useAlert } from 'dashboard/composables';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default defineComponent({
  components: { NextButton },
  props: {
    inbox: {
      type: Object,
      required: true,
    },
  },
  setup(props) {
    const { t } = useI18n();
    const store = useStore();
    const isLoading = ref(false);
    const isConnected = ref(false);
    const qrCode = ref('');
    const statusMessage = ref('');
    let pollInterval = null;

    // Get accountId reliably from global store (preferred) or inbox prop
    const accountId = computed(() => {
      return store.getters['getCurrentAccountId'] || props.inbox.account_id;
    });

    // Helper for API URL
    const getApiUrl = endpoint => {
      if (!accountId.value) throw new Error('Account ID missing');
      return `/api/v1/accounts/${accountId.value}/inboxes/${props.inbox.id}/wuzapi${endpoint}`;
    };

    const fetchStatus = async () => {
      if (!accountId.value) return;

      try {
        const response = await window.axios.get(getApiUrl(''));
        console.log('Status Response:', response.data);

        const data = response.data;
        // Wuzapi format: { data: { connected: true, jid: "...", details: "..." } }
        const wuzapiData = data.data || {};

        const isWuzapiConnected =
          wuzapiData.connected === true && !!wuzapiData.jid;

        // Also keep legacy check just in case payload differs
        const legacyStatus = data.status || data.state;
        const isLegacyConnected = ['CONNECTED', 'inChat', 'success'].includes(
          legacyStatus
        );

        isConnected.value = isWuzapiConnected || isLegacyConnected;
        statusMessage.value = wuzapiData.details || legacyStatus || 'Unknown';

        if (isConnected.value) {
          console.log('✅ Wuzapi Connected! JID:', wuzapiData.jid);
          qrCode.value = '';
          stopPolling();
        }
      } catch (error) {
        console.error('Status Fetch Error:', error);
        statusMessage.value =
          error.response?.data?.error || error.message || 'Check failed';
      }
    };

    const fetchQrCode = async () => {
      try {
        console.log('Fetching QR code...');
        const response = await window.axios.get(getApiUrl('/qr'));
        console.log('QR Response Data:', response.data);

        // Backend now normalizes to 'qrcode' in most cases, but we keep robust checks
        const d = response.data;
        const qrcodeData =
          d.qrcode ||
          d.qr ||
          d.QRCode ||
          d.data?.qrcode ||
          d.data?.qr ||
          (typeof d.data === 'string' ? d.data : null);

        if (qrcodeData && qrcodeData.length > 20) {
          console.log('QR Code found, updating UI...');
          qrCode.value = qrcodeData;
          startPolling();
        } else {
          console.warn(
            'No QR code in response. Checking status as fallback...'
          );
          // Fallback: maybe we are already connected?
          await fetchStatus();
          if (!isConnected.value) {
            statusMessage.value = 'QR Code not received and not connected.';
          }
        }
      } catch (error) {
        console.error('QR Fetch Error:', error);
        statusMessage.value =
          error.response?.data?.error || 'Failed to load QR';
      }
    };

    const handleConnect = async () => {
      console.log('Connect button clicked');
      if (!accountId.value) {
        console.error('Account ID missing');
        useAlert('Error: Account ID missing');
        return;
      }

      isLoading.value = true;
      try {
        // 1. Call Connect
        const connectUrl = getApiUrl('/connect');
        console.log('Calling connect:', connectUrl);
        await window.axios.post(connectUrl);
        console.log('Connect successful, fetching QR...');
        // 2. Fetch QR
        await fetchQrCode();
      } catch (error) {
        console.error('Connect failed:', error);
        useAlert(error.response?.data?.error || 'Connection failed');
      } finally {
        isLoading.value = false;
      }
    };

    const disconnect = async () => {
      isLoading.value = true;
      try {
        await window.axios.post(getApiUrl('/disconnect'));
        useAlert(t('INBOX_MGMT.EDIT.WUZAPI.DISCONNECT_SUCCESS'));
        isConnected.value = false;
        qrCode.value = '';
        fetchStatus();
      } catch (error) {
        useAlert(t('INBOX_MGMT.EDIT.WUZAPI.DISCONNECT_ERROR'));
      } finally {
        isLoading.value = false;
      }
    };

    const startPolling = () => {
      if (pollInterval) return;
      // Poll every 5 seconds to check status AND refresh QR code
      pollInterval = setInterval(async () => {
        await fetchStatus();
        // If still not connected (and polling hasn't been stopped by fetchStatus), refresh QR
        if (pollInterval && !isConnected.value) {
          await fetchQrCode();
        }
      }, 5000);
    };

    const stopPolling = () => {
      if (pollInterval) {
        clearInterval(pollInterval);
        pollInterval = null;
      }
    };

    onMounted(() => {
      fetchStatus();
    });

    onUnmounted(() => {
      stopPolling();
    });

    return {
      isLoading,
      isConnected,
      qrCode,
      statusMessage,
      fetchStatus,
      disconnect,
      handleConnect,
      accountId,
    };
  },
});
</script>

<template>
  <div class="mx-8 mt-6">
    <div class="bg-white p-6 rounded-lg border border-n-weak">
      <h3 class="text-lg font-medium text-n-slate-12 mb-4">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WUZAPI') }} -
        {{ $t('INBOX_MGMT.SETTINGS_POPUP.MESSENGER_CONFIG') }}
      </h3>

      <div v-if="accountId" class="flex flex-col items-center">
        <div v-if="isConnected" class="flex flex-col items-center">
          <div class="text-green-600 font-bold mb-4 flex items-center gap-2">
            <span class="i-woot-checkmark-circle text-2xl"></span>
            {{ $t('INBOX_MGMT.EDIT.WUZAPI.CONNECTED') }}
          </div>
          <p class="text-n-slate-11 mb-4">
            {{ $t('INBOX_MGMT.EDIT.WUZAPI.CONNECTED_DESC') }}
          </p>
          <NextButton
            color="ruby"
            :is-loading="isLoading"
            :label="$t('INBOX_MGMT.EDIT.WUZAPI.DISCONNECT')"
            @click="disconnect"
          />
        </div>

        <div v-else class="flex flex-col items-center">
          <div v-if="qrCode" class="mb-4">
            <img
              :src="qrCode"
              alt="Whatsapp QR Code"
              class="w-64 h-64 border rounded"
            />
            <p class="text-center text-sm text-n-slate-11 mt-2">
              {{ $t('INBOX_MGMT.EDIT.WUZAPI.SCAN_QR') }}
            </p>
          </div>

          <div v-else class="flex flex-col items-center mb-4">
            <p class="text-n-slate-11 mb-4">
              {{
                $t('INBOX_MGMT.EDIT.WUZAPI.CONNECT_DESC') ||
                'Click to initiate connection'
              }}
            </p>
            <NextButton
              color="blue"
              :is-loading="isLoading"
              :label="
                $t('INBOX_MGMT.EDIT.WUZAPI.CONNECT') || 'Connect WhatsApp'
              "
              @click="handleConnect"
            />
          </div>

          <div class="mt-4 text-xs text-n-slate-10">
            Status: {{ statusMessage }}
          </div>
        </div>
      </div>

      <div v-else class="text-red-600 p-4">
        Error: Account ID not loaded. Please refresh the page.
      </div>
    </div>
  </div>
</template>
