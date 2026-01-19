import ApiClient from './ApiClient';

class FrequentQuestionsAPI extends ApiClient {
  constructor() {
    super('frequent_questions', { accountScoped: true });
  }

  get() {
    return this.axios.get(this.url);
  }
}

export default new FrequentQuestionsAPI();
