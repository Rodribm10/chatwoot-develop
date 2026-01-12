/* global axios */
import ApiClient from '../ApiClient';

class CaptainInboxes extends ApiClient {
  constructor() {
    super('captain/assistants', { accountScoped: true });
  }

  get({ assistantId } = {}) {
    return axios.get(`${this.url}/${assistantId}/inboxes`);
  }

  create(params = {}) {
    const { assistantId, inboxId } = params;
    return axios.post(`${this.url}/${assistantId}/inboxes`, {
      inbox: { inbox_id: inboxId },
    });
  }

  delete(params = {}) {
    const { assistantId, inboxId } = params;
    return axios.delete(`${this.url}/${assistantId}/inboxes/${inboxId}`);
  }

  update(inboxId, params = {}) {
    const { assistantId, always_use_reminder_tool } = params;
    return axios.patch(`${this.url}/${assistantId}/inboxes/${inboxId}`, {
      inbox: { always_use_reminder_tool },
    });
  }
}

export default new CaptainInboxes();
