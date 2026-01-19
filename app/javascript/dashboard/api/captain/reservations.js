/* global axios */
import ApiClient from '../ApiClient';

class CaptainReservations extends ApiClient {
  constructor() {
    super('captain/reservations', { accountScoped: true });
  }

  get({
    page = 1,
    conversationId,
    inboxId,
    contactId,
    unit_id,
    status,
    date_from,
    date_to,
  } = {}) {
    return axios.get(this.url, {
      params: {
        page,
        conversation_id: conversationId,
        inbox_id: inboxId,
        contact_id: contactId,
        unit_id,
        status,
        date_from,
        date_to,
      },
    });
  }

  update(id, data) {
    return axios.patch(`${this.url}/${id}`, data);
  }

  delete(id) {
    return axios.delete(`${this.url}/${id}`);
  }
}

export default new CaptainReservations();
