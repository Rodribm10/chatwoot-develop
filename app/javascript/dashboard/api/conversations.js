/* global axios */
import ApiClient from './ApiClient';

class ConversationApi extends ApiClient {
  constructor() {
    super('conversations', { accountScoped: true });
  }

  getLabels(conversationID) {
    return axios.get(`${this.url}/${conversationID}/labels`);
  }

  updateLabels(conversationID, labels) {
    return axios.post(`${this.url}/${conversationID}/labels`, { labels });
  }

  getCrmInsight(conversationID) {
    return axios.get(`${this.url}/${conversationID}/crm_insight`);
  }

  refreshCrmInsight(conversationID) {
    return axios.post(`${this.url}/${conversationID}/crm_insight/refresh`);
  }
}

export default new ConversationApi();
