import Controller from '@ember/controller';
import { action } from '@ember/object';

export default class AuthenticatedRepositoriesShowController extends Controller {
  @action
  save() {
    this.model.save();
  }

  @action
  updateStreamConfig(index, value) {
    this.set('model.streamConfigs.' + index, value);
  }

  @action
  addStreamConfig() {
    let config = '';
    this.get('model.streamConfigs').pushObject(config);
  }

  @action
  removeStreamConfig(config) {
    this.get('model.streamConfigs').removeObject(config);
  }
}
