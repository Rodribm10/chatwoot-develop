/* global axios */
import ApiClient from '../ApiClient';

class CaptainReminders extends ApiClient {
  constructor() {
    super('captain/reminders', { accountScoped: true });
  }

  get({ page = 1, conversationId, inboxId, contactId, from, to } = {}) {
    return axios.get(this.url, {
      params: {
        page,
        conversation_id: conversationId,
        inbox_id: inboxId,
        contact_id: contactId,
        from,
        to,
      },
    });
  }
}

export default new CaptainReminders();
