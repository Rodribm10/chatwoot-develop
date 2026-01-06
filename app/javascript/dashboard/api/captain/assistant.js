/* global axios */
import ApiClient from '../ApiClient';

class CaptainAssistant extends ApiClient {
  constructor() {
    super('captain/assistants', { accountScoped: true });
  }

  get({ page = 1, searchKey } = {}) {
    return axios.get(this.url, {
      params: {
        page,
        searchKey,
      },
    });
  }

  playground({ assistantId, messageContent, messageHistory }) {
    return axios.post(`${this.url}/${assistantId}/playground`, {
      message_content: messageContent,
      message_history: messageHistory,
    });
  }

  getTools(assistantId) {
    return axios.get(`${this.url}/${assistantId}/tools`);
  }

  create(data) {
    return axios.post(this.url, {
      assistant: data,
    });
  }

  update(id, data) {
    return axios.patch(`${this.url}/${id}`, {
      assistant: data,
    });
  }

  updateTool(assistantId, toolKey, config) {
    return axios.patch(`${this.url}/${assistantId}/tools/${toolKey}`, config);
  }
}

export default new CaptainAssistant();
