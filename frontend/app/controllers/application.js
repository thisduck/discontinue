import Controller from '@ember/controller';
import config from '../config/environment';
import { inject as service } from '@ember/service';

export default Controller.extend({
  session: service(),
  config: config.torii.providers['github-oauth2'],

  actions: {
    logout() {
      this.get('session').invalidate();
    }
  }

});
