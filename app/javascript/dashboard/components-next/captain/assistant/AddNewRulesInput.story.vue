<script setup>
import AddNewRulesInput from './AddNewRulesInput.vue';
</script>

<template>
  <!-- eslint-disable vue/no-bare-strings-in-template -->
  <Story
    title="Captain/Assistant/AddNewRulesInput"
    :layout="{ type: 'grid', width: '800px' }"
  >
    <Variant title="Default">
      <div class="px-6 py-4 bg-n-background">
        <AddNewRulesInput
          placeholder="Type in another response guideline..."
          label="Add and save (↵)"
        />
      </div>
    </Variant>
  </Story>
</template>
