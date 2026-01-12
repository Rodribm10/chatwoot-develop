<script setup>
/* eslint-disable no-console, no-alert, vue/no-bare-strings-in-template, vue/no-static-inline-styles */
import { ref, reactive, onMounted, onUnmounted, computed, watch } from 'vue';

// --- State ---
const view = ref('form'); // form, payment, success
const isDataLoading = ref(true);
const isLoading = ref(false);
const isCopied = ref(false);
const submissionStatus = ref({
  loading: false,
  error: null,
  success: false,
  reservationId: null, // Track ID for polling
  pix: {
    copyPasteCode: '',
    qrCodeValue: '',
  },
  scarcityText: '',
});

const appConfig = reactive({
  title: 'Reserva Premium',
  subtitle: 'Hotel 1001 Noites Prime',
});

const formData = reactive({
  nome: '',
  checkInDateTime: '',
  telefone: '',
  email: '',
  cpf: '',
  observacao: '',
  selectedBrand: '',
  selectedUnit: '',
  selectedCategory: '',
  stayDuration: '',
  selectedExtras: [], // Future Phase
});

// Options State
const brands = ref([]);
// const units = ref([]); // Removed unused var
const pricings = ref([]);
const extras = ref([]);

const unitOptions = ref([]);
const categoryOptions = ref([]);
const durationOptions = ref([]);

// Price State
const calculatedPrice = ref(null);
const isPriceLoading = ref(false);

// --- API Methods ---
const fetchMasterData = async () => {
  isDataLoading.value = true;
  try {
    const pathParts = window.location.pathname.split('/');
    const accountIdIndex = pathParts.indexOf('accounts') + 1;
    const accountId = pathParts[accountIdIndex];

    const response = await fetch(
      `/public/api/v1/captain/master_data?account_id=${accountId}`
    );
    if (!response.ok) throw new Error('Failed to load data');
    const data = await response.json();

    brands.value = data.brands;
    pricings.value = data.pricings;
    extras.value = data.extras;
  } catch (error) {
    // console.error("Master Data Error:", error);
  } finally {
    isDataLoading.value = false;
  }
};

// --- Watchers & Computed ---

// When Brand changes
const handleBrandChange = () => {
  formData.selectedUnit = '';
  formData.selectedCategory = '';
  formData.stayDuration = '';

  const brand = brands.value.find(b => String(b.id) === formData.selectedBrand);
  if (brand) {
    unitOptions.value = brand.units.map(u => ({
      value: String(u.id),
      label: u.name,
    }));
    durationOptions.value = brand.stay_durations.map(d => ({
      value: d,
      label: d,
    }));
  } else {
    unitOptions.value = [];
    durationOptions.value = [];
  }
};

// When Unit changes
const handleUnitChange = () => {
  formData.selectedCategory = '';
  const brand = brands.value.find(b => String(b.id) === formData.selectedBrand);
  const unit = brand?.units.find(u => String(u.id) === formData.selectedUnit);

  if (
    unit &&
    unit.visible_suite_categories &&
    unit.visible_suite_categories.length > 0
  ) {
    categoryOptions.value = unit.visible_suite_categories.map(c => ({
      value: c,
      label: c,
    }));
  } else if (
    brand &&
    brand.suite_categories &&
    brand.suite_categories.length > 0
  ) {
    categoryOptions.value = brand.suite_categories.map(c => ({
      value: c,
      label: c,
    }));
  } else {
    categoryOptions.value = [];
  }
};

// Price Calculation Logic
const suiteImage = computed(() => {
  if (!formData.selectedBrand || !formData.selectedCategory) return null;
  const brand = brands.value.find(b => String(b.id) === formData.selectedBrand);
  if (!brand) return null;

  const images = brand.suiteImages || brand.suite_images || {};
  return images[formData.selectedCategory] || null;
});

// Price Calculation Logic
const calculatePrice = () => {
  if (
    !formData.selectedBrand ||
    !formData.selectedCategory ||
    !formData.stayDuration ||
    !formData.checkInDateTime
  ) {
    calculatedPrice.value = null;
    return;
  }

  isPriceLoading.value = true;
  // Simulate async price lookup or local calc
  setTimeout(() => {
    try {
      const brandId = parseInt(formData.selectedBrand, 10);
      const date = new Date(formData.checkInDateTime);
      const dayIndex = date.getDay(); // 0 = Sunday, 6 = Saturday

      const daysMap = [
        'DOMINGO',
        'SEGUNDA',
        'TERÇA',
        'QUARTA',
        'QUINTA',
        'SEXTA',
        'SÁBADO',
      ];
      const currentDayName = daysMap[dayIndex];

      // Find matching pricing row
      const priceRow = pricings.value.find(p => {
        if (p.captain_brand_id !== brandId) return false;
        if (p.suite_category !== formData.selectedCategory) return false;
        if (p.duration !== formData.stayDuration) return false;

        // Check day range
        const range = (p.day_range || p.dayRange || '').toUpperCase();

        if (range.includes(' A ')) {
          if (range === 'SEGUNDA A QUARTA') {
            return ['SEGUNDA', 'TERÇA', 'QUARTA'].includes(currentDayName);
          }
          if (range === 'QUINTA A DOMINGO') {
            return ['QUINTA', 'SEXTA', 'SÁBADO', 'DOMINGO'].includes(
              currentDayName
            );
          }
          return false;
        }

        const days = range.split(',').map(d => d.trim());
        return days.includes(currentDayName);
      });

      if (priceRow) {
        calculatedPrice.value = parseFloat(priceRow.price);
      } else {
        calculatedPrice.value = null;
      }
    } catch (e) {
      // console.error(e);
    } finally {
      isPriceLoading.value = false;
    }
  }, 300);
};

watch(
  () => [
    formData.selectedBrand,
    formData.selectedCategory,
    formData.stayDuration,
    formData.checkInDateTime,
  ],
  calculatePrice
);

// --- Actions ---

const calculateCheckOut = (startStr, durationStr) => {
  const start = new Date(startStr);
  let hoursToAdd = 4;
  if (durationStr?.toUpperCase().includes('PERNOITE')) {
    hoursToAdd = 12;
  }
  const end = new Date(start.getTime() + hoursToAdd * 60 * 60 * 1000);
  return end.toISOString();
};

const formatCurrency = val => {
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'BRL',
  }).format(val);
};

const handleCopyPix = () => {
  if (submissionStatus.value?.pix?.copyPasteCode) {
    navigator.clipboard.writeText(submissionStatus.value.pix.copyPasteCode);
    isCopied.value = true;
    setTimeout(() => {
      isCopied.value = false;
    }, 2000);
  }
};

const handleResetForm = () => {
  view.value = 'form';
  formData.nome = '';
  formData.telefone = '';
  formData.cpf = '';
  formData.email = '';
  formData.checkInDateTime = '';
  formData.observacao = '';
  formData.selectedBrand = '';
  formData.selectedUnit = '';
  formData.selectedCategory = '';
  formData.stayDuration = '';
  submissionStatus.value = null;
  calculatedPrice.value = null;
};

const generateScarcityMessage = () => {
  const messages = [
    '🔥 Resta apenas 1 suíte disponível para esta data!',
    '⚡ Alta demanda! 2 pessoas estão vendo esta suíte agora.',
    '💎 Última chance! O hotel está quase lotado.',
    '⏳ Segure sua vaga! Restam apenas 2 suítes.',
    '👀 Muita procura para esta data. Garanta sua reserva!',
  ];
  return messages[Math.floor(Math.random() * messages.length)];
};

// Functions defined before use
const triggerConfetti = () => {
  import('canvas-confetti')
    .then(confetti => {
      confetti.default({
        particleCount: 150,
        spread: 70,
        origin: { y: 0.6 },
      });
    })
    .catch(() => {});
};

let pollingInterval = null;
const checkPaymentStatus = async () => {
  if (!submissionStatus.value?.reservationId) return;

  try {
    const response = await fetch(
      `/public/api/v1/captain/reservations/${submissionStatus.value.reservationId}/status`
    );
    if (!response.ok) return;

    const data = await response.json();

    if (data.payment_status === 'paid') {
      clearInterval(pollingInterval);
      view.value = 'success';
      triggerConfetti();
    }
  } catch (error) {
    // console.error('Error polling status:', error);
  }
};

const startPolling = () => {
  if (pollingInterval) clearInterval(pollingInterval);
  pollingInterval = setInterval(checkPaymentStatus, 5000);
};

const handleSubmit = async () => {
  if (!calculatedPrice.value) {
    return;
  }

  isLoading.value = true;
  submissionStatus.value = null;

  try {
    const pathParts = window.location.pathname.split('/');
    const accountId = pathParts[pathParts.indexOf('accounts') + 1];

    const payload = {
      brand_id: formData.selectedBrand,
      unit_id: formData.selectedUnit,
      contact_name: formData.nome,
      phone_number: formData.telefone.replace(/\D/g, ''),
      email: formData.email,
      cpf: formData.cpf.replace(/\D/g, ''),
      check_in_at: formData.checkInDateTime,
      duration_minutes: 0,
      check_out_at: calculateCheckOut(
        formData.checkInDateTime,
        formData.stayDuration
      ),
      total_amount: calculatedPrice.value,
      metadata: {
        category: formData.selectedCategory,
        stay_duration: formData.stayDuration,
        observacao: formData.observacao,
      },
    };

    const response = await fetch(
      `/public/api/v1/captain/reservations?account_id=${accountId}`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
      }
    );

    const result = await response.json();

    if (response.ok) {
      if (result.metadata?.pix) {
        submissionStatus.value = {
          message:
            'Sua reserva foi iniciada! Realize o pagamento via Pix para confirmar.',
          type: 'success',
          reservationId: result.reservation_id,
          pix: result.metadata.pix,
          scarcityText: generateScarcityMessage(),
        };
        view.value = 'payment';
        // Trigger polling
        startPolling();
      } else {
        submissionStatus.value = {
          message: 'Reserva criada, mas falha ao gerar Pix. Entre em contato.',
          type: 'error',
        };
        view.value = 'payment';
      }
    } else {
      throw new Error(result.error || 'Falha ao criar reserva');
    }
  } catch (error) {
    // console.error('Submit Error:', error);
    // alert('Erro: ' + error.message);
  } finally {
    isLoading.value = false;
  }
};

onUnmounted(() => {
  if (pollingInterval) clearInterval(pollingInterval);
});

// Lifecycle
onMounted(() => {
  fetchMasterData();
});

const formatPhone = event => {
  let value = event.target.value.replace(/\D/g, '');
  if (value.length > 11) value = value.slice(0, 11);

  if (value.length > 10) {
    value = value.replace(/^(\d{2})(\d{5})(\d{4}).*/, '($1) $2-$3');
  } else if (value.length > 5) {
    value = value.replace(/^(\d{2})(\d{4})(\d{0,4}).*/, '($1) $2-$3');
  } else if (value.length > 2) {
    value = value.replace(/^(\d{2})(\d{0,5}).*/, '($1) $2');
  }

  formData.telefone = value;
  event.target.value = value;
};

const formatCPF = event => {
  let value = event.target.value.replace(/\D/g, '');
  if (value.length > 11) value = value.slice(0, 11);

  value = value.replace(/(\d{3})(\d)/, '$1.$2');
  value = value.replace(/(\d{3})(\d)/, '$1.$2');
  value = value.replace(/(\d{3})(\d{1,2})$/, '$1-$2');

  formData.cpf = value;
  event.target.value = value;
};

const isValidEmail = email => {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
};

const isFormValid = computed(() => {
  return (
    formData.nome.trim().length > 0 &&
    formData.telefone.length >= 14 && // (XX) XXXXX-XXXX is 15 chars, or (XX) XXXX-XXXX is 14
    formData.cpf.length === 14 && // XXX.XXX.XXX-XX
    isValidEmail(formData.email) &&
    formData.checkInDateTime &&
    formData.selectedBrand &&
    formData.selectedUnit &&
    formData.selectedCategory &&
    formData.stayDuration
  );
});

const viewTitle = computed(() => {
  if (view.value === 'payment') return 'Pagamento Seguro';
  if (view.value === 'success') return 'Reserva Confirmada';
  return appConfig.title;
});
</script>

<template>
  <!-- eslint-disable vue/no-bare-strings-in-template, vue/no-static-inline-styles -->
  <div
    class="min-h-screen py-6 px-4 sm:px-6 lg:px-8 flex flex-col items-center justify-center bg-fixed"
    style="background: linear-gradient(135deg, #0a1a2f 0%, #1b3b5f 100%)"
  >
    <div
      class="w-full max-w-3xl bg-white rounded-[2rem] shadow-2xl overflow-hidden border border-white/10 relative"
    >
      <!-- Decorative Top Accent -->
      <div
        class="absolute top-0 left-0 w-full h-2 bg-gradient-to-r from-[#1B3B5F] to-[#1E90FF]"
      />

      <div class="p-6 sm:p-12">
        <div
          class="flex justify-between items-start mb-10 border-b border-[#1B3B5F]/10 pb-6"
        >
          <div class="space-y-1">
            <h1
              class="text-2xl sm:text-3xl font-extrabold text-[#1B3B5F] tracking-tight"
            >
              {{ viewTitle }}
            </h1>
            <p
              v-if="view === 'form'"
              class="text-[#9CA3AF] text-sm font-medium"
            >
              {{ appConfig.subtitle }}
            </p>
          </div>
        </div>

        <!-- LOADING STATE -->
        <div
          v-if="isDataLoading"
          class="text-center py-20 flex flex-col items-center justify-center space-y-4"
        >
          <div
            class="w-8 h-8 border-4 border-[#1E90FF] border-t-transparent rounded-full animate-spin"
          />
          <p class="text-[#9CA3AF] font-medium animate-pulse">
            Carregando dados...
          </p>
        </div>

        <!-- SUCCESS VIEW -->
        <div
          v-else-if="view === 'success'"
          class="text-center space-y-6 p-10 bg-[#F8FAFC] border border-[#1B3B5F]/10 rounded-3xl shadow-inner animate-fade-in"
        >
          <div
            class="mx-auto w-24 h-24 bg-green-100 rounded-full flex items-center justify-center mb-6 shadow-md"
          >
            <!-- Success Icon -->
            <svg
              class="h-12 w-12 text-green-600"
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              stroke-width="2"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
          </div>
          <h2 class="text-3xl font-extrabold text-[#1B3B5F]">
            Pagamento Confirmado!
          </h2>
          <p class="text-[#9CA3AF] text-lg">
            Sua reserva está 100% garantida.<br />Enviamos os detalhes para o
            seu e-mail.
          </p>
          <div class="pt-6">
            <button
              class="w-full px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              @click="handleResetForm"
            >
              Fazer Nova Reserva
            </button>
          </div>
        </div>

        <!-- PAYMENT VIEW -->
        <div
          v-else-if="view === 'payment'"
          class="text-center space-y-6 animate-fade-in"
        >
          <div
            class="p-4 bg-[#F8FAFC] rounded-2xl border border-[#1B3B5F]/10 mb-6"
          >
            <p class="text-[#1B3B5F] font-medium">
              {{ submissionStatus?.message }}
            </p>
          </div>

          <!-- Scarcity Trigger -->
          <div
            v-if="submissionStatus?.scarcityText"
            class="animate-pulse bg-red-50 border border-red-100 p-3 rounded-xl"
          >
            <p
              class="text-red-600 font-bold text-sm flex items-center justify-center gap-2"
            >
              <i class="i-lucide-flame text-lg" />
              {{ submissionStatus.scarcityText }}
            </p>
          </div>

          <!-- WhatsApp Warning -->
          <div class="text-center px-4">
            <p class="text-sm text-gray-600">
              Após o pagamento, você receberá a confirmação imediatamente no seu
              <strong class="text-green-600">WhatsApp</strong>
              <span class="font-mono text-xs">({{ formData.telefone }})</span>.
              <br />
              <span class="text-xs text-gray-400 block mt-1"
                >Certifique-se que o número informado está correto.</span
              >
            </p>
          </div>

          <div class="pt-4 pb-2 text-left">
            <label
              class="block text-xs font-bold text-[#1B3B5F] uppercase tracking-wide mb-2"
              >Código Pix Copia e Cola</label
            >
            <div class="relative group">
              <input
                type="text"
                readonly
                :value="submissionStatus?.pix?.copyPasteCode || ''"
                class="w-full bg-[#F8FAFC] border-[1.5px] border-[#1B3B5F]/20 rounded-xl p-4 pr-28 text-sm text-[#1B3B5F] font-mono focus:outline-none focus:border-[#1E90FF]"
              />
              <div class="absolute right-2 top-1/2 -translate-y-1/2">
                <button
                  class="px-3 py-1 bg-gray-200 hover:bg-gray-300 rounded text-sm font-medium transition-colors"
                  @click="handleCopyPix"
                >
                  {{ isCopied ? 'Copiado!' : 'Copiar' }}
                </button>
              </div>
            </div>
          </div>

          <!-- QR Code Image -->
          <div
            v-if="submissionStatus?.pix?.qrCodeValue"
            class="flex justify-center mt-4"
          >
            <div
              class="p-4 bg-white rounded-xl shadow-lg border border-gray-100"
            >
              <p class="text-xs text-gray-500 mb-2">
                Escaneie o QR Code no app do seu banco
              </p>
              <img
                :src="`https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${encodeURIComponent(
                  submissionStatus.pix.copyPasteCode
                )}`"
                alt="QR Code do PIX"
                class="w-48 h-48 object-contain mix-blend-multiply"
              />
            </div>
          </div>

          <div class="pt-4 border-t border-[#1B3B5F]/10">
            <button
              class="w-full text-[#9CA3AF] hover:text-[#1B3B5F] py-2"
              @click="handleResetForm"
            >
              Cancelar e Voltar
            </button>
          </div>
        </div>

        <!-- FORM VIEW -->
        <form v-else class="space-y-4" @submit.prevent="handleSubmit">
          <div
            class="bg-[#F8FAFC] p-6 rounded-2xl border border-[#1B3B5F]/10 mb-8 shadow-sm space-y-4"
          >
            <h3
              class="text-[#1B3B5F] font-bold text-sm uppercase tracking-wider mb-4 border-b border-[#1B3B5F]/10 pb-2"
            >
              Detalhes da Estadia
            </h3>

            <!-- Brand Selection -->
            <div>
              <label
                for="brand"
                class="block text-sm font-medium text-gray-700"
              >
                Marca <span class="text-red-500">*</span>
              </label>
              <select
                id="brand"
                v-model="formData.selectedBrand"
                class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md shadow-sm"
                @change="handleBrandChange"
              >
                <option value="" disabled>Selecione a marca</option>
                <option
                  v-for="brand in brands"
                  :key="brand.id"
                  :value="String(brand.id)"
                >
                  {{ brand.name }}
                </option>
              </select>
            </div>

            <!-- Unit and Duration -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label
                  for="unit"
                  class="block text-sm font-medium text-gray-700"
                  >Unidade <span class="text-red-500">*</span></label
                >
                <select
                  id="unit"
                  v-model="formData.selectedUnit"
                  :disabled="!unitOptions.length"
                  class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md shadow-sm disabled:bg-gray-100"
                  @change="handleUnitChange"
                >
                  <option value="" disabled>Selecione a unidade</option>
                  <option
                    v-for="unit in unitOptions"
                    :key="unit.value"
                    :value="unit.value"
                  >
                    {{ unit.label }}
                  </option>
                </select>
              </div>
              <div>
                <label
                  for="duration"
                  class="block text-sm font-medium text-gray-700"
                  >Permanência <span class="text-red-500">*</span></label
                >
                <select
                  id="duration"
                  v-model="formData.stayDuration"
                  :disabled="!durationOptions.length"
                  class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md shadow-sm disabled:bg-gray-100"
                >
                  <option value="" disabled>Selecione o tempo</option>
                  <option
                    v-for="opt in durationOptions"
                    :key="opt.value"
                    :value="opt.value"
                  >
                    {{ opt.label }}
                  </option>
                </select>
              </div>
            </div>

            <!-- Category -->
            <div>
              <label
                for="category"
                class="block text-sm font-medium text-gray-700"
                >Categoria da Suíte <span class="text-red-500">*</span></label
              >
              <select
                id="category"
                v-model="formData.selectedCategory"
                :disabled="!categoryOptions.length"
                class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md shadow-sm disabled:bg-gray-100"
              >
                <option value="" disabled>Selecione a categoria</option>
                <option
                  v-for="opt in categoryOptions"
                  :key="opt.value"
                  :value="opt.value"
                >
                  {{ opt.label }}
                </option>
              </select>
            </div>

            <!-- Checkin Date -->
            <div>
              <label
                for="checkin"
                class="block text-sm font-medium text-gray-700"
                >Data e Horário do Check-in
                <span class="text-red-500">*</span></label
              >
              <input
                id="checkin"
                v-model="formData.checkInDateTime"
                type="datetime-local"
                required
                class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
              />
            </div>
          </div>

          <!-- Photos View -->
          <div v-if="suiteImage" class="my-6 animate-fade-in">
            <div
              class="rounded-2xl overflow-hidden shadow-lg border border-[#1B3B5F]/10"
            >
              <img
                :src="suiteImage"
                alt="Suite Preview"
                class="w-full h-64 object-cover"
              />
            </div>
          </div>

          <!-- Price Display -->
          <div class="my-8">
            <div
              v-if="isPriceLoading"
              class="text-center p-6 bg-[#F8FAFC] rounded-2xl border border-[#1B3B5F]/10"
            >
              <div
                class="w-6 h-6 border-2 border-[#1E90FF] border-t-transparent rounded-full animate-spin mx-auto mb-2"
              />
              <p class="text-sm text-[#9CA3AF]">Calculando valor...</p>
            </div>
            <div
              v-else-if="calculatedPrice !== null"
              class="relative overflow-hidden p-6 bg-[#F8FAFC] border-[1.5px] border-[#1E90FF]/20 rounded-2xl animate-fade-in shadow-lg shadow-[#1E90FF]/5"
            >
              <div
                class="absolute top-0 right-0 bg-[#1E90FF] text-white text-[10px] font-bold px-3 py-1 rounded-bl-lg"
              >
                PREÇO ESTIMADO
              </div>
              <div class="space-y-4">
                <div
                  class="flex justify-between items-center text-sm text-[#1B3B5F]"
                >
                  <span class="font-medium">Valor Total da Reserva</span>
                  <span class="font-bold text-lg">{{
                    formatCurrency(calculatedPrice)
                  }}</span>
                </div>

                <div
                  class="flex justify-between items-center text-sm text-[#9CA3AF]"
                >
                  <span>Pagar no check-in (50%)</span>
                  <span class="font-medium">{{
                    formatCurrency(calculatedPrice / 2)
                  }}</span>
                </div>
                <div
                  class="pt-4 border-t border-[#1B3B5F]/10 flex justify-between items-end"
                >
                  <div>
                    <p
                      class="text-xs font-bold text-[#1E90FF] uppercase tracking-wider mb-1"
                    >
                      Entrada via Pix (50%)
                    </p>
                    <p class="text-[#9CA3AF] text-xs">
                      Necessário para confirmar
                    </p>
                  </div>
                  <span
                    class="text-3xl font-extrabold text-[#1B3B5F] tracking-tight"
                  >
                    {{ formatCurrency(calculatedPrice / 2) }}
                  </span>
                </div>
              </div>
            </div>
          </div>

          <!-- User Details -->
          <div
            class="bg-[#F8FAFC] p-6 rounded-2xl border border-[#1B3B5F]/10 mb-8 shadow-sm space-y-4"
          >
            <h3
              class="text-[#1B3B5F] font-bold text-sm uppercase tracking-wider mb-4 border-b border-[#1B3B5F]/10 pb-2"
            >
              Seus Dados
            </h3>
            <div>
              <label class="block text-sm font-medium text-gray-700"
                >Nome Completo <span class="text-red-500">*</span></label
              >
              <input
                v-model="formData.nome"
                type="text"
                required
                placeholder="Seu nome completo"
                class="mt-1 block w-full border-gray-300 rounded-xl shadow-sm focus:ring-[#1E90FF] focus:border-[#1E90FF] text-base py-3 px-4"
              />
            </div>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700"
                  >Telefone / WhatsApp
                  <span class="text-red-500">*</span></label
                >
                <input
                  :value="formData.telefone"
                  type="tel"
                  required
                  class="mt-1 block w-full border-gray-300 rounded-xl shadow-sm focus:ring-[#1E90FF] focus:border-[#1E90FF] text-base py-3 px-4"
                  placeholder="(99) 99999-9999"
                  maxlength="15"
                  @input="formatPhone"
                />
                <p class="text-xs text-gray-400 mt-1 ml-1">
                  Formato: (99) 99999-9999
                </p>
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700"
                  >CPF <span class="text-red-500">*</span></label
                >
                <input
                  :value="formData.cpf"
                  type="text"
                  required
                  class="mt-1 block w-full border-gray-300 rounded-xl shadow-sm focus:ring-[#1E90FF] focus:border-[#1E90FF] text-base py-3 px-4"
                  placeholder="000.000.000-00"
                  maxlength="14"
                  @input="formatCPF"
                />
              </div>
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700"
                >E-mail <span class="text-red-500">*</span></label
              >
              <input
                v-model="formData.email"
                type="email"
                required
                class="mt-1 block w-full border-gray-300 rounded-xl shadow-sm focus:ring-[#1E90FF] focus:border-[#1E90FF] text-base py-3 px-4"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-700"
                >Observação</label
              >
              <textarea
                v-model="formData.observacao"
                rows="2"
                class="mt-1 block w-full border-gray-300 rounded-xl shadow-sm focus:ring-[#1E90FF] focus:border-[#1E90FF] text-base py-3 px-4"
              />
            </div>
          </div>

          <!-- Submit Button -->
          <button
            type="submit"
            :disabled="!isFormValid || isLoading || isDataLoading"
            class="w-full flex justify-center py-4 px-6 border border-transparent rounded-xl shadow-xl shadow-[#1E90FF]/30 hover:shadow-[#1E90FF]/50 text-lg font-bold text-white bg-[#1E90FF] hover:bg-[#1B3B5F] focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#1E90FF] disabled:bg-gray-300 disabled:shadow-none disabled:cursor-not-allowed transition-all duration-300 uppercase tracking-wide"
          >
            {{ isLoading ? 'Processando...' : 'Confirmar e Pagar Reserva' }}
          </button>
        </form>
      </div>
    </div>

    <footer class="text-center text-xs font-medium text-white/40 mt-8">
      &copy; {{ new Date().getFullYear() }} {{ appConfig.title }} &bull;
      Experiência Exclusiva
    </footer>
  </div>
</template>

<style>
/* Global overrides to ensure background covers the entire page */
body {
  background: linear-gradient(135deg, #0a1a2f 0%, #1b3b5f 100%) fixed !important;
  margin: 0;
  min-height: 100vh;
}
</style>

<style scoped>
/* Specific overrides if needed */
</style>
