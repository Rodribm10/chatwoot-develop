import ApiClient from '../../api/ApiClient';

class UnitsAPI extends ApiClient {
  constructor() {
    super('captain/units', { accountScoped: true });
  }

  get(params) {
    return window.axios.get(this.url, { params });
  }

  update(id, data) {
    return window.axios.patch(`${this.url}/${id}`, data);
  }
}

export default new UnitsAPI();
