import CaptainAssistantAPI from 'dashboard/api/captain/assistant';
import { createStore } from '../storeFactory';

export default createStore({
  name: 'CaptainAssistant',
  API: CaptainAssistantAPI,
  actions: (mutationTypes) => ({
    fetchTools: async (_, { assistantId }) => {
      try {
        const { data } = await CaptainAssistantAPI.getTools(assistantId);
        return data;
      } catch (error) {
        throw new Error(error);
      }
    },
    updateTool: async (_, { assistantId, toolKey, config }) => {
      try {
        const { data } = await CaptainAssistantAPI.updateTool(
          assistantId,
          toolKey,
          config
        );
        return data;
      } catch (error) {
        throw new Error(error);
      }
    },
  }),
});
