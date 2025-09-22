/* global axios */
import ApiClient from './ApiClient';

class ConversationApi extends ApiClient {
  constructor() {
    super('conversations', { accountScoped: true });
  }

  /**
   * Obtiene las etiquetas de una conversación
   * @param {number|string} conversationID
   * @returns {Promise}
   */
  getLabels(conversationID) {
    return axios.get(`${this.url}/${conversationID}/labels`);
  }

  /**
   * Actualiza las etiquetas de una conversación
   * @param {number|string} conversationID
   * @param {Array} labels
   * @returns {Promise}
   */
  updateLabels(conversationID, labels) {
    return axios.post(`${this.url}/${conversationID}/labels`, { labels });
  }

  /**
   * Envía un mensaje en una conversación
   * @param {number|string} conversationID
   * @param {string} content
   * @param {Object} options
   * @param {string} options.message_type - Tipo de mensaje, por defecto "outgoing"
   * @param {boolean} options.isPrivate - Indica si es privado, por defecto true
   * @returns {Promise}
   */
  sendMessage(conversationID, content, { message_type = "outgoing", isPrivate = true } = {}) {
    return axios.post(`${this.url}/${conversationID}/messages`, {
      content,
      message_type,
      private: isPrivate,
    });
  }
}

export default new ConversationApi();
