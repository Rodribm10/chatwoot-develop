/* global axios */
import ApiClient from '../ApiClient';

class CaptainInboxAutomations extends ApiClient {
  constructor() {
    super('captain/inbox_automations', { accountScoped: true });
  }

  get({ page = 1, inboxId } = {}) {
    return axios.get(this.url, {
      params: {
        page,
        inbox_id: inboxId,
      },
    });
  }
}

export default new CaptainInboxAutomations();
