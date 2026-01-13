<script setup>
import { computed, onMounted, ref, nextTick } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import CaptainPaywall from 'dashboard/components-next/captain/pageComponents/Paywall.vue';
import DeleteDialog from 'dashboard/components-next/captain/pageComponents/DeleteDialog.vue';
import AssetCard from 'dashboard/components-next/captain/pageComponents/asset/AssetCard.vue';
import CreateAssetDialog from 'dashboard/components-next/captain/pageComponents/asset/CreateAssetDialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import EditAssetDialog from 'dashboard/components-next/captain/pageComponents/asset/EditAssetDialog.vue';

const store = useStore();
const uiFlags = useMapGetter('captainAssets/getUIFlags');
const assets = useMapGetter('captainAssets/getRecords');
const assetsMeta = useMapGetter('captainAssets/getMeta');

const isFetching = computed(() => uiFlags.value?.fetchingList || false);

const selectedAsset = ref(null);
const deleteAssetDialog = ref(null);
const showCreateDialog = ref(false);
const createAssetDialog = ref(null);
const showEditDialog = ref(false);
const editAssetDialog = ref(null);

const fetchAssets = (page = 1) => {
  store.dispatch('captainAssets/get', { page });
};

const handleCreateAsset = () => {
  showCreateDialog.value = true;
  nextTick(() => createAssetDialog.value.dialogRef.open());
};

const handleCreateDialogClose = () => {
  showCreateDialog.value = false;
};

const handleEditDialogClose = () => {
  showEditDialog.value = false;
};

const handleDelete = () => {
  nextTick(() => {
    deleteAssetDialog.value.dialogRef.open();
  });
};

const handleAction = ({ action, id }) => {
  if (!assets.value) return;
  selectedAsset.value = assets.value.find(asset => id === asset.id);
  if (action === 'delete') {
    handleDelete();
  } else if (action === 'edit') {
    showEditDialog.value = true;
    nextTick(() => editAssetDialog.value.dialogRef.open());
  }
};

const onDeleteSuccess = () => {
  if (assets.value?.length === 0 && assetsMeta.value?.page > 1) {
    fetchAssets(assetsMeta.value.page - 1);
  }
};

const onPageChange = page => fetchAssets(page);

onMounted(() => {
  fetchAssets();
});
</script>

<template>
  <!-- eslint-disable vue/no-bare-strings-in-template -->
  <PageLayout
    :header-title="$t('CAPTAIN.ASSETS.HEADER')"
    :header-description="$t('CAPTAIN.ASSETS.DESCRIPTION')"
    :button-label="$t('CAPTAIN.ASSETS.ADD_NEW')"
    :button-policy="['administrator']"
    :total-count="assetsMeta?.totalCount || 0"
    :current-page="assetsMeta?.page || 1"
    :show-pagination-footer="!isFetching && !!assets?.length"
    :is-fetching="isFetching"
    :is-empty="!assets?.length"
    :show-know-more="false"
    :show-assistant-switcher="false"
    :feature-flag="FEATURE_FLAGS.CAPTAIN"
    @update:current-page="onPageChange"
    @click="handleCreateAsset"
  >
    <template #paywall>
      <CaptainPaywall />
    </template>

    <template #emptyState>
      <div class="flex flex-col items-center gap-3 py-8 text-center">
        <i class="text-3xl i-ph-image text-n-slate-11" />
        <p class="text-sm text-n-slate-11">
          {{ $t('CAPTAIN.ASSETS.EMPTY_STATE') }}
        </p>
        <Button
          :label="$t('CAPTAIN.ASSETS.ADD_NEW')"
          icon="i-lucide-plus"
          size="sm"
          @click="handleCreateAsset"
        />
      </div>
    </template>

    <template #body>
      <div class="flex flex-col gap-4">
        <AssetCard
          v-for="asset in assets"
          :id="asset.id"
          :key="asset.id"
          :name="asset.name"
          :file-url="asset.file_url"
          @action="handleAction"
        />
      </div>
    </template>

    <CreateAssetDialog
      v-if="showCreateDialog"
      ref="createAssetDialog"
      @close="handleCreateDialogClose"
    />
    <EditAssetDialog
      v-if="showEditDialog && selectedAsset"
      ref="editAssetDialog"
      :asset="selectedAsset"
      @close="handleEditDialogClose"
    />
    <DeleteDialog
      v-if="selectedAsset"
      ref="deleteAssetDialog"
      type="Assets"
      translation-key="ASSETS"
      :entity="selectedAsset"
      @delete-success="onDeleteSuccess"
    />
  </PageLayout>
</template>
