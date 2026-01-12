/* global axios */
import ApiClient from '../ApiClient';

class CaptainAsset extends ApiClient {
  constructor() {
    super('captain/assets', { accountScoped: true });
  }

  get({ page = 1 } = {}) {
    return axios.get(this.url, {
      params: {
        page,
      },
    });
  }
}

export default new CaptainAsset();
