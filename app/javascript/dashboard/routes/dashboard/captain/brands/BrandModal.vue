<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import Modal from 'dashboard/components/Modal.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
  brand: {
    type: Object,
    default: null,
  },
});

const emit = defineEmits(['close', 'save']);
const { t } = useI18n(); // eslint-disable-line no-unused-vars

const name = ref('');
// suiteItems will hold objects: { name: 'Standard', image: 'url' }
const suiteItems = ref([]);
const stayDurations = ref('');

const resetForm = () => {
  name.value = '';
  suiteItems.value = [{ name: '', image: '' }];
  stayDurations.value = '';
};

watch(
  () => props.brand,
  newBrand => {
    if (newBrand) {
      name.value = newBrand.name;
      // Parse suite categories and images (handle both snake_case and camelCase)
      const categories =
        newBrand.suite_categories || newBrand.suiteCategories || [];
      const images = newBrand.suite_images || newBrand.suiteImages || {};

      if (Array.isArray(categories) && categories.length > 0) {
        suiteItems.value = categories.map(cat => ({
          name: cat,
          image: images[cat] || '',
        }));
      } else if (typeof categories === 'string') {
        // Handle legacy string format if exists
        suiteItems.value = categories
          .split(',')
          .map(s => ({ name: s.trim(), image: '' }));
      } else {
        suiteItems.value = [{ name: '', image: '' }];
      }

      const durations = newBrand.stay_durations || newBrand.stayDurations;
      stayDurations.value = Array.isArray(durations)
        ? durations.join(', ')
        : durations || '';
    } else {
      resetForm();
    }
  },
  { immediate: true }
);

const addSuiteItem = () => {
  suiteItems.value.push({ name: '', image: '' });
};

const removeSuiteItem = index => {
  suiteItems.value.splice(index, 1);
};

const onClose = () => {
  emit('close');
  resetForm();
};

const onSave = () => {
  // Convert suiteItems back to separate structures
  const validItems = suiteItems.value.filter(item => item.name.trim() !== '');
  const categories = validItems.map(item => item.name.trim());

  const images = {};
  validItems.forEach(item => {
    if (item.image && item.image.trim() !== '') {
      images[item.name.trim()] = item.image.trim();
    }
  });

  const payload = {
    name: name.value,
    suite_categories: categories,
    suite_images: images,
    stay_durations: stayDurations.value
      .split(',')
      .map(s => s.trim())
      .filter(s => s),
  };
  emit('save', payload);
  onClose();
};

const headerTitle = computed(() =>
  props.brand ? 'Editar Marca' : 'Nova Marca'
);
const saveLabel = computed(() => (props.brand ? 'Atualizar' : 'Criar'));
</script>

<template>
  <!-- eslint-disable vue/no-bare-strings-in-template -->
  <Modal :show="show" :on-close="onClose">
    <div
      class="flex flex-col gap-4 p-6 w-[600px] bg-white dark:bg-slate-900 rounded-lg"
    >
      <h2 class="text-xl font-semibold text-slate-800 dark:text-slate-100">
        {{ headerTitle }}
      </h2>

      <div class="flex flex-col gap-4">
        <div>
          <label
            class="block text-sm font-medium text-slate-700 dark:text-slate-200 mb-1"
          >
            Nome da Marca
          </label>
          <Input v-model="name" placeholder="Ex: Hotel Prime" />
        </div>

        <div>
          <label
            class="block text-sm font-medium text-slate-700 dark:text-slate-200 mb-1"
          >
            Categorias de Suíte e Fotos
          </label>

          <div
            class="flex flex-col gap-2 max-h-[300px] overflow-y-auto pr-2 mb-2"
          >
            <div
              v-for="(item, index) in suiteItems"
              :key="index"
              class="flex gap-2 items-start"
            >
              <div class="flex-1">
                <Input
                  v-model="item.name"
                  placeholder="Nome (Ex: Presidencial)"
                />
              </div>
              <div class="flex-1">
                <Input
                  v-model="item.image"
                  placeholder="URL da Imagem (https://...)"
                />
              </div>
              <button
                class="mt-2 text-red-500 hover:text-red-700 p-1"
                title="Remover"
                @click="removeSuiteItem(index)"
              >
                <i class="i-lucide-trash-2" />
              </button>
            </div>
          </div>

          <button
            class="text-sm text-blue-600 hover:text-blue-800 flex items-center gap-1 font-medium bg-transparent border-none p-0 cursor-pointer"
            @click="addSuiteItem"
          >
            <i class="i-lucide-plus" /> Adicionar Categoria
          </button>

          <p class="text-xs text-slate-500 mt-2 dark:text-slate-400">
            Insira o nome da categoria e opcionalmente a URL da foto.
          </p>
        </div>

        <div>
          <label
            class="block text-sm font-medium text-slate-700 dark:text-slate-200 mb-1"
          >
            Permanências (separadas por vírgula)
          </label>
          <Input
            v-model="stayDurations"
            placeholder="Ex: 2h, 4h, Pernoite, Diária"
          />
        </div>
      </div>

      <div
        class="flex justify-end gap-2 mt-4 pt-4 border-t border-slate-100 dark:border-slate-800"
      >
        <Button variant="ghost" @click="onClose"> Cancelar </Button>
        <Button @click="onSave">
          {{ saveLabel }}
        </Button>
      </div>
    </div>
  </Modal>
</template>
