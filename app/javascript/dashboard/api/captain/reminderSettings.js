/* global axios */
import ApiClient from '../ApiClient';

class CaptainReminderSettings extends ApiClient {
  constructor() {
    super('inboxes', { accountScoped: true });
  }

  get(inboxId) {
    return axios.get(`${this.url}/${inboxId}/captain/reminder_settings`);
  }

  update(inboxId, payload) {
    return axios.patch(
      `${this.url}/${inboxId}/captain/reminder_settings`,
      payload
    );
  }
}

export default new CaptainReminderSettings();
