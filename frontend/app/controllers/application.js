import Controller from '@ember/controller';
import { inject as service } from '@ember/service';

export default Controller.extend({
  session: service(),
  currentUser: service('current-user'),

  actions: {
    logout() {
      this.get('session').invalidate();
    },

    login() {
      this.get('session').authenticate('authenticator:torii', 'github');
    }
  }

});
