import CaptainAssetAPI from 'dashboard/api/captain/asset';
import { createStore } from '../storeFactory';
import { throwErrorMessage } from 'dashboard/store/utils/api';

export default createStore({
  name: 'CaptainAsset',
  API: CaptainAssetAPI,
  actions: mutationTypes => ({
    async update({ commit }, { id, payload }) {
      commit(mutationTypes.SET_UI_FLAG, { updatingItem: true });
      try {
        const response = await CaptainAssetAPI.update(id, payload);
        commit(mutationTypes.EDIT, response.data);
        return response.data;
      } catch (error) {
        return throwErrorMessage(error);
      } finally {
        commit(mutationTypes.SET_UI_FLAG, { updatingItem: false });
      }
    },
  }),
});
