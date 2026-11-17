import Controller from '@ember/controller';
import { inject as service } from '@ember/service';
import config from '../config/environment';

export default Controller.extend({
  session: service(),
  currentUser: service('current-user'),
  demoMode: config.APP.demoMode,

  actions: {
    login() {
      this.get('session').authenticate('authenticator:torii', 'github');
    },
    loginDemo() {
      return this.get('session').authenticate('authenticator:token', { demo: true })
        .then(() => this.get('currentUser').load());
    }
  }
});
