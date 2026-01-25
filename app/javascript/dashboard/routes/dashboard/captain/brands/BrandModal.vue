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
          const keywords =
            this.brand.suiteKeywords || this.brand.suite_keywords || {};

          this.suiteCategories = categories.map(cat => ({
            name: cat,
            image: images[cat] || '',
            keywords: keywords[cat] || '',
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
      this.newCategoryKeywords = '';
      this.v$.$reset();
    },
    addCategory() {
      if (!this.newCategoryName) return;
      this.suiteCategories.push({
        name: this.newCategoryName,
        image: this.newCategoryImage,
        keywords: this.newCategoryKeywords,
      });
      this.newCategoryName = '';
      this.newCategoryImage = '';
      this.newCategoryKeywords = '';
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
      const keywords = this.suiteCategories.reduce((acc, curr) => {
        if (curr.keywords) acc[curr.name] = curr.keywords;
        return acc;
      }, {});

      const payload = {
        name: this.name,
        suite_categories: categories,
        suite_images: images,
        suite_keywords: keywords,
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
  <WootModal
    :show="show"
    :on-close="() => $emit('close')"
    class-name="!max-w-5xl !w-full"
  >
    <div
      class="flex flex-col w-full bg-white dark:bg-slate-900 rounded-lg shadow-xl overflow-hidden"
    >
      <!-- Header -->
      <div
        class="px-6 py-3 border-b border-slate-200 dark:border-slate-800 flex justify-between items-center"
      >
        <h2 class="text-lg font-semibold text-slate-800 dark:text-slate-100">
          {{ headerTitle }}
        </h2>
      </div>

      <!-- Body -->
      <div class="flex-1 p-5 flex flex-col gap-3">
        <!-- Brand Name -->
        <WootInput
          v-model="name"
          label="Nome da Marca"
          placeholder="Ex: Hotel 1001 Noites"
          :error="v$.name.$error ? 'Nome é obrigatório' : ''"
        />

        <!-- Suite Categories -->
        <div
          class="bg-slate-50 dark:bg-slate-800 p-3 rounded-lg border border-slate-200 dark:border-slate-700"
        >
          <div class="flex items-center justify-between mb-2">
            <label
              class="block text-sm font-medium text-slate-700 dark:text-slate-200"
            >
              Categorias de Suíte
            </label>
          </div>

          <!-- Add New Category - Function Bar -->
          <div class="flex flex-col gap-2 mb-2">
            <div class="flex gap-2">
              <input
                v-model="newCategoryName"
                type="text"
                placeholder="Nome (Ex: Standard)"
                class="flex-1 text-sm py-1.5 border-slate-200 dark:border-slate-700 rounded-md bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-100 placeholder:text-slate-400"
                @keydown.enter.prevent="addCategory"
              />
              <input
                v-model="newCategoryImage"
                type="text"
                placeholder="URL da Imagem"
                class="flex-1 text-sm py-1.5 border-slate-200 dark:border-slate-700 rounded-md bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-100 placeholder:text-slate-400"
                @keydown.enter.prevent="addCategory"
              />
              <button
                class="px-3 py-1.5 bg-blue-600 text-white rounded-md hover:bg-blue-700 text-sm font-medium shrink-0"
                title="Adicionar Categoria"
                @click.prevent="addCategory"
              >
                <i class="i-lucide-plus" />
              </button>
            </div>
            <input
              v-model="newCategoryKeywords"
              type="text"
              placeholder="Palavras-chave (Ex: jacuzzi, hidro) - Opcional"
              class="w-full text-sm py-1.5 border-slate-200 dark:border-slate-700 rounded-md bg-white dark:bg-slate-900 text-slate-800 dark:text-slate-100 placeholder:text-slate-400"
              @keydown.enter.prevent="addCategory"
            />
          </div>

          <!-- Categories Grid -->
          <div v-if="suiteCategories.length > 0" class="grid grid-cols-2 gap-2">
            <div
              v-for="(cat, idx) in suiteCategories"
              :key="idx"
              class="flex items-center justify-between bg-white dark:bg-slate-900 p-1.5 rounded border border-slate-200 dark:border-slate-600"
            >
              <div class="flex flex-col flex-1 min-w-0 mr-2">
                <div class="flex items-center gap-2">
                  <span
                    class="font-medium text-sm text-slate-800 dark:text-slate-100"
                  >
                    {{ cat.name }}
                  </span>
                  <span
                    v-if="cat.keywords"
                    class="text-xs text-slate-500 truncate"
                    :title="cat.keywords"
                  >
                    <i class="i-lucide-key size-3 inline-block mr-0.5" />
                    {{ cat.keywords }}
                  </span>
                </div>

                <span
                  v-if="cat.image"
                  class="text-xs text-slate-400 truncate"
                  :title="cat.image"
                >
                  <i class="i-lucide-image size-3 inline-block mr-0.5" />
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
            Nenhuma categoria adicionada.
          </p>
        </div>

        <!-- Stays -->
        <WootInput
          v-model="stayDurations"
          label="Durações Aceitas"
          placeholder="Ex: 2h, 4h, Pernoite, Diária"
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
