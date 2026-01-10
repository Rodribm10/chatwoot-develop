import { createStore } from '../storeFactory';
import CaptainToolsAPI from '../../api/captain/tools';
import { throwErrorMessage } from 'dashboard/store/utils/api';

const toolsStore = createStore({
  name: 'Tools',
  API: CaptainToolsAPI,
  // Custom getters for tools with string IDs
  getters: {
    getRecords: state => {
      return state.records;
    },
    getRecord: state => id =>
      state.records.find(record => record.id === id) || {},
  },
  actions: mutations => ({
    getTools: async ({ commit }) => {
      commit(mutations.SET_UI_FLAG, { fetchingList: true });
      try {
        const response = await CaptainToolsAPI.get();
        commit(mutations.SET, response.data);
        commit(mutations.SET_UI_FLAG, { fetchingList: false });
        return response.data;
      } catch (error) {
        commit(mutations.SET_UI_FLAG, { fetchingList: false });
        return throwErrorMessage(error);
      }
    },
  }),
});

export default toolsStore;
