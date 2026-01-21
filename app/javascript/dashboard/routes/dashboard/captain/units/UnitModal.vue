<script>
/* eslint-disable @intlify/vue-i18n/no-raw-text, vue/no-bare-strings-in-template */
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import WootModal from 'dashboard/components/Modal.vue';
import WootInput from 'dashboard/components-next/input/Input.vue';
import WootButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    WootModal,
    WootInput,
    WootButton,
  },
  props: {
    show: {
      type: Boolean,
      default: false,
    },
    unit: {
      type: Object,
      default: null,
    },
  },
  emits: ['close', 'save'],
  setup() {
    return {
      v$: useVuelidate(),
      alert: useAlert(),
    };
  },
  data() {
    return {
      name: '',
      captain_brand_id: '',
      inter_client_id: '',
      inter_client_secret: '',
      inter_pix_key: '',
      inter_cert_path: '',
      inter_key_path: '',
      inter_account_number: '',
      webhook_url: '',
      leader_whatsapp: '',
      reservation_source_tag: '',
      inbox_id: '',
      brands: [],
      inboxes: [],
      isLoadingBrands: false,
      plug_play_id: '',
      plug_play_token: '',
      reservations_sync_enabled: false,
    };
  },
  validations() {
    return {
      name: { required },
      captain_brand_id: { required },
    };
  },
  watch: {
    show(val) {
      if (val) {
        this.fetchBrands();
        this.fetchInboxes();
        if (this.unit) {
          this.name = this.unit.name;
          this.captain_brand_id = this.unit.captain_brand_id;
          this.inter_client_id = this.unit.inter_client_id;
          this.inter_client_secret = this.unit.inter_client_secret;
          this.inter_pix_key = this.unit.inter_pix_key;
          this.inter_cert_path = this.unit.inter_cert_path;
          this.inter_key_path = this.unit.inter_key_path;
          this.inter_account_number = this.unit.inter_account_number;
          this.webhook_url = this.unit.webhook_url;
          this.leader_whatsapp = this.unit.leader_whatsapp || '';
          this.reservation_source_tag = this.unit.reservation_source_tag || '';
          this.inbox_id = this.unit.inbox_id;
          this.plug_play_id = this.unit.plug_play_id || '';
          this.plug_play_token = this.unit.plug_play_token || '';
          this.reservations_sync_enabled =
            this.unit.reservations_sync_enabled || false;
        } else {
          this.resetForm();
        }
      }
    },
  },
  methods: {
    resetForm() {
      this.name = '';
      this.captain_brand_id = '';
      this.inter_client_id = '';
      this.inter_client_secret = '';
      this.inter_pix_key = '';
      this.inter_cert_path = '';
      this.inter_key_path = '';
      this.inter_account_number = '';
      this.webhook_url = '';
      this.leader_whatsapp = '';
      this.reservation_source_tag = '';
      this.inbox_id = '';
      this.plug_play_id = '';
      this.plug_play_token = '';
      this.reservations_sync_enabled = false;
      this.v$.$reset();
    },
    async fetchInboxes() {
      try {
        const { data } = await window.axios.get(
          `/api/v1/accounts/${this.$route.params.accountId}/inboxes`
        );
        this.inboxes = data.payload;
      } catch (error) {
        // Silent error or alert
      }
    },
    async fetchBrands() {
      this.isLoadingBrands = true;
      try {
        const { data } = await window.axios.get(
          `/api/v1/accounts/${this.$route.params.accountId}/captain/brands`
        );
        this.brands = data;
      } catch (error) {
        this.alert(this.$t('CAPTAIN.UNITS.ERROR_FETCHING'));
      } finally {
        this.isLoadingBrands = false;
      }
    },
    async save() {
      this.v$.$touch();
      if (this.v$.$invalid) return;

      const payload = {
        name: this.name,
        captain_brand_id: this.captain_brand_id,
        inter_client_id: this.inter_client_id,
        inter_client_secret: this.inter_client_secret,
        inter_pix_key: this.inter_pix_key,
        inter_cert_path: this.inter_cert_path,
        inter_key_path: this.inter_key_path,
        inter_account_number: this.inter_account_number,
        webhook_url: this.webhook_url,
        leader_whatsapp: this.leader_whatsapp,
        reservation_source_tag: this.reservation_source_tag,
        inbox_id: this.inbox_id,
        plug_play_id: this.plug_play_id,
        plug_play_token: this.plug_play_token,
        reservations_sync_enabled: this.reservations_sync_enabled,
      };

      try {
        let response;
        if (this.unit) {
          response = await window.axios.put(
            `/api/v1/accounts/${this.$route.params.accountId}/captain/units/${this.unit.id}`,
            { unit: payload }
          );
        } else {
          response = await window.axios.post(
            `/api/v1/accounts/${this.$route.params.accountId}/captain/units`,
            { unit: payload }
          );
        }
        this.$emit('save', response.data);
        this.$emit('close');
        this.alert(this.$t('CAPTAIN.UNITS.SAVE_SUCCESS'));
      } catch (error) {
        this.alert(this.$t('CAPTAIN.UNITS.SAVE_ERROR'));
      }
    },
  },
};
</script>

<template>
  <!-- eslint-disable @intlify/vue-i18n/no-raw-text, vue/no-bare-strings-in-template -->
  <WootModal :show="show" :on-close="() => $emit('close')">
    <div
      class="flex flex-col w-[600px] bg-white dark:bg-slate-900 rounded-lg shadow-xl overflow-hidden"
    >
      <!-- Header -->
      <div
        class="px-6 py-4 border-b border-slate-200 dark:border-slate-800 flex justify-between items-center"
      >
        <h2 class="text-lg font-semibold text-slate-800 dark:text-slate-100">
          {{
            unit
              ? $t('CAPTAIN.UNITS.EDIT_TITLE')
              : $t('CAPTAIN.UNITS.ADD_TITLE')
          }}
        </h2>
      </div>

      <!-- Scrollable Body -->
      <div class="flex-1 overflow-y-auto p-6 max-h-[65vh] flex flex-col gap-5">
        <WootInput
          v-model="name"
          :label="$t('CAPTAIN.UNITS.FORM.NAME_LABEL')"
          :placeholder="$t('CAPTAIN.UNITS.FORM.NAME_PLACEHOLDER')"
          :error="v$.name.$error ? $t('CAPTAIN.UNITS.FORM.NAME_ERROR') : ''"
        />

        <WootInput
          v-model="leader_whatsapp"
          :label="$t('CAPTAIN.UNITS.FORM.LEADER_WHATSAPP_LABEL')"
          :placeholder="$t('CAPTAIN.UNITS.FORM.LEADER_WHATSAPP_PLACEHOLDER')"
        />

        <div>
          <label
            class="block mb-1.5 text-sm font-medium text-slate-700 dark:text-slate-200"
          >
            {{ $t('CAPTAIN.UNITS.FORM.BRAND_LABEL') }}
          </label>
          <div class="relative">
            <select
              v-model="captain_brand_id"
              class="w-full h-10 px-3 py-2 border rounded-md border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-100 focus:outline-none focus:ring-1 focus:ring-blue-500 appearance-none"
            >
              <option value="" disabled>
                {{ $t('CAPTAIN.UNITS.FORM.BRAND_PLACEHOLDER') }}
              </option>
              <option v-for="brand in brands" :key="brand.id" :value="brand.id">
                {{ brand.name }}
              </option>
            </select>
            <!-- Chevron Icon for Select -->
            <div
              class="absolute inset-y-0 right-0 flex items-center px-2 pointer-events-none text-slate-500"
            >
              <i class="i-lucide-chevron-down text-base" />
            </div>
          </div>
          <span
            v-if="v$.captain_brand_id.$error"
            class="mt-1 text-xs text-red-500"
          >
            {{ $t('forms.invalid') }}
          </span>
        </div>

        <div>
          <label
            class="block mb-1.5 text-sm font-medium text-slate-700 dark:text-slate-200"
          >
            <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
            Caixa de Entrada (WhatsApp de Notificação)
          </label>
          <div class="relative">
            <select
              v-model="inbox_id"
              class="w-full h-10 px-3 py-2 border rounded-md border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-100 focus:outline-none focus:ring-1 focus:ring-blue-500 appearance-none"
            >
              <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
              <option value="">Selecione um Inbox (Opcional)</option>
              <option
                v-for="inbox in inboxes"
                :key="inbox.id"
                :value="inbox.id"
              >
                <!-- eslint-disable-next-line @intlify/vue-i18n/no-raw-text -->
                {{ inbox.name }} ({{ inbox.channel_type }})
              </option>
            </select>
            <div
              class="absolute inset-y-0 right-0 flex items-center px-2 pointer-events-none text-slate-500"
            >
              <i class="i-lucide-chevron-down text-base" />
            </div>
          </div>
        </div>

        <div class="my-1 h-px bg-slate-100 dark:bg-slate-800" />
        <h4
          class="text-sm font-semibold text-slate-800 dark:text-slate-100 uppercase tracking-wide"
        >
          {{ $t('CAPTAIN.UNITS.FORM.PIX_CONFIG_TITLE') }}
        </h4>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <WootInput
            v-model="inter_client_id"
            :label="$t('CAPTAIN.UNITS.FORM.CLIENT_ID')"
            placeholder="Client ID"
          />
          <WootInput
            v-model="inter_client_secret"
            :label="$t('CAPTAIN.UNITS.FORM.CLIENT_SECRET')"
            placeholder="Client Secret"
          />
          <WootInput
            v-model="inter_pix_key"
            :label="$t('CAPTAIN.UNITS.FORM.PIX_KEY')"
            placeholder="Chave Pix"
            class="md:col-span-2"
          />
          <WootInput
            v-model="inter_cert_path"
            :label="$t('CAPTAIN.UNITS.FORM.CERT_PATH')"
            placeholder="/app/certs/..."
          />
          <WootInput
            v-model="inter_key_path"
            :label="$t('CAPTAIN.UNITS.FORM.KEY_PATH')"
            placeholder="/app/certs/..."
          />
          <WootInput
            v-model="inter_account_number"
            :label="$t('CAPTAIN.UNITS.FORM.ACCOUNT_NUMBER')"
            placeholder="Opcional"
            class="md:col-span-2"
          />
        </div>

        <div class="my-1 h-px bg-slate-100 dark:bg-slate-800" />
        <h4
          class="text-sm font-semibold text-slate-800 dark:text-slate-100 uppercase tracking-wide"
        >
          {{ $t('CAPTAIN.UNITS.FORM.WEBHOOK_TITLE') }}
        </h4>
        <WootInput
          v-model="webhook_url"
          :label="$t('CAPTAIN.UNITS.FORM.WEBHOOK_URL')"
          placeholder="https://webhook.n8n.cloud/webhook/..."
        />

        <div class="my-1 h-px bg-slate-100 dark:bg-slate-800" />
        <h4
          class="text-sm font-semibold text-slate-800 dark:text-slate-100 uppercase tracking-wide"
        >
          {{ 'Integração Config' }}
        </h4>

        <div class="grid grid-cols-1 gap-4">
          <WootInput
            v-model="plug_play_id"
            label="PlugPlay ID"
            placeholder="ID da Unidade na PlugPlay"
          />
          <WootInput
            v-model="plug_play_token"
            label="PlugPlay Token"
            placeholder="Token de Acesso"
            type="password"
          />
          <WootInput
            v-model="reservation_source_tag"
            :label="$t('CAPTAIN.UNITS.FORM.RESERVATION_SOURCE_TAG_LABEL')"
            :placeholder="
              $t('CAPTAIN.UNITS.FORM.RESERVATION_SOURCE_TAG_PLACEHOLDER')
            "
          />
          <div class="flex items-center gap-2">
            <input
              id="sync_enabled"
              v-model="reservations_sync_enabled"
              type="checkbox"
              class="w-4 h-4 text-blue-600 bg-gray-100 border-gray-300 rounded focus:ring-blue-500 dark:focus:ring-blue-600 dark:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600"
            />
            <label
              for="sync_enabled"
              class="text-sm font-medium text-slate-700 dark:text-slate-200"
            >
              Ativar Sincronização de Reservas
            </label>
          </div>
        </div>
      </div>

      <!-- Footer -->
      <div
        class="px-6 py-4 bg-slate-50 dark:bg-slate-800/50 border-t border-slate-100 dark:border-slate-800 flex justify-end gap-2"
      >
        <WootButton variant="ghost" @click="$emit('close')">
          {{ $t('CAPTAIN.FORM.CANCEL') }}
        </WootButton>
        <WootButton :disabled="isLoadingBrands" @click="save">
          {{ unit ? $t('CAPTAIN.FORM.EDIT') : $t('CAPTAIN.FORM.CREATE') }}
        </WootButton>
      </div>
    </div>
  </WootModal>
</template>
