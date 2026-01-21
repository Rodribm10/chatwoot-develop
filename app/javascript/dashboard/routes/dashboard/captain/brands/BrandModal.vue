<script>
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
    brand: {
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
      suiteCategories: [],
      stayDurations: '',
      // Temporary state for new category input
      newCategoryName: '',
      newCategoryImage: '',
    };
  },
  validations() {
    return {
      name: { required },
    };
  },
  computed: {
    headerTitle() {
      return this.brand ? 'Editar Marca' : 'Nova Marca';
    },
    saveLabel() {
      return this.brand ? 'Atualizar Marca' : 'Criar Marca';
    },
  },
  watch: {
    show(val) {
      if (val) {
        if (this.brand) {
          this.name = this.brand.name;
          this.stayDurations = (
            this.brand.stayDurations ||
            this.brand.stay_durations ||
            []
          ).join(', ');

          const categories =
            this.brand.suiteCategories || this.brand.suite_categories || [];
          const images =
            this.brand.suiteImages || this.brand.suite_images || {};

          this.suiteCategories = categories.map(cat => ({
            name: cat,
            image: images[cat] || '',
          }));
        } else {
          this.resetForm();
        }
      }
    },
  },
  methods: {
    resetForm() {
      this.name = '';
      this.suiteCategories = [];
      this.stayDurations = '';
      this.newCategoryName = '';
      this.newCategoryImage = '';
      this.v$.$reset();
    },
    addCategory() {
      if (!this.newCategoryName) return;
      this.suiteCategories.push({
        name: this.newCategoryName,
        image: this.newCategoryImage,
      });
      this.newCategoryName = '';
      this.newCategoryImage = '';
    },
    removeCategory(index) {
      this.suiteCategories.splice(index, 1);
    },
    onSave() {
      this.v$.$touch();
      if (this.v$.$invalid) return;

      const categories = this.suiteCategories.map(c => c.name);
      const images = this.suiteCategories.reduce((acc, curr) => {
        if (curr.image) acc[curr.name] = curr.image;
        return acc;
      }, {});

      const payload = {
        name: this.name,
        suite_categories: categories,
        suite_images: images,
        stay_durations: this.stayDurations
          .split(',')
          .map(s => s.trim())
          .filter(Boolean),
      };
      this.$emit('save', payload);
    },
  },
};
</script>

<template>
  <!-- eslint-disable vue/no-bare-strings-in-template, @intlify/vue-i18n/no-raw-text -->
  <WootModal :show="show" :on-close="() => $emit('close')">
    <div
      class="flex flex-col w-[600px] bg-white dark:bg-slate-900 rounded-lg shadow-xl overflow-hidden"
    >
      <!-- Header -->
      <div
        class="px-6 py-4 border-b border-slate-200 dark:border-slate-800 flex justify-between items-center"
      >
        <h2 class="text-lg font-semibold text-slate-800 dark:text-slate-100">
          {{ headerTitle }}
        </h2>
      </div>

      <!-- Scrollable Body -->
      <div class="flex-1 overflow-y-auto p-6 max-h-[65vh] flex flex-col gap-5">
        <!-- Brand Name -->
        <WootInput
          v-model="name"
          label="Nome da Marca"
          placeholder="Ex: Hotel 1001 Noites"
          :error="v$.name.$error ? 'Nome é obrigatório' : ''"
        />

        <!-- Suite Categories -->
        <div
          class="bg-slate-50 dark:bg-slate-800 p-4 rounded-lg border border-slate-200 dark:border-slate-700"
        >
          <div class="flex items-center justify-between mb-3">
            <label
              class="block text-sm font-medium text-slate-700 dark:text-slate-200"
            >
              Categorias de Suíte
            </label>
          </div>

          <div class="flex gap-2 mb-3">
            <input
              v-model="newCategoryName"
              type="text"
              placeholder="Nome (Ex: Standard)"
              class="flex-1 text-sm border-slate-200 dark:border-slate-700 rounded-md bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-100"
              @keydown.enter.prevent="addCategory"
            />
            <input
              v-model="newCategoryImage"
              type="text"
              placeholder="URL da Imagem"
              class="flex-1 text-sm border-slate-200 dark:border-slate-700 rounded-md bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-100"
              @keydown.enter.prevent="addCategory"
            />
            <button
              class="px-3 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 text-sm font-medium"
              @click.prevent="addCategory"
            >
              <i class="i-lucide-plus" />
            </button>
          </div>

          <div v-if="suiteCategories.length > 0" class="space-y-2">
            <div
              v-for="(cat, idx) in suiteCategories"
              :key="idx"
              class="flex items-center justify-between bg-white dark:bg-slate-900 p-2 rounded border border-slate-200 dark:border-slate-600"
            >
              <div class="flex flex-col">
                <span
                  class="font-medium text-sm text-slate-800 dark:text-slate-100"
                >
                  {{ cat.name }}
                </span>
                <span
                  v-if="cat.image"
                  class="text-xs text-slate-500 truncate max-w-[200px]"
                >
                  {{ cat.image }}
                </span>
              </div>
              <button
                class="text-red-500 hover:text-red-700 p-1"
                title="Remover categoria"
                @click="removeCategory(idx)"
              >
                <i class="i-lucide-trash-2 size-4" />
              </button>
            </div>
          </div>
          <p
            v-else
            class="text-sm text-slate-500 dark:text-slate-400 italic text-center py-2"
          >
            Adicione as categorias de quartos disponíveis para esta marca.
          </p>
        </div>

        <!-- Stays -->
        <WootInput
          v-model="stayDurations"
          label="Durações Aceitas"
          placeholder="Ex: 2h, 4h, Pernoite, Diária (separados por vírgula)"
        />
      </div>

      <!-- Footer -->
      <div
        class="px-6 py-4 bg-slate-50 dark:bg-slate-800/50 border-t border-slate-100 dark:border-slate-800 flex justify-end gap-2"
      >
        <WootButton variant="ghost" @click="$emit('close')">
          Cancelar
        </WootButton>
        <WootButton @click="onSave">
          {{ saveLabel }}
        </WootButton>
      </div>
    </div>
  </WootModal>
</template>
