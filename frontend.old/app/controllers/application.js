import Controller from '@ember/controller';
import { inject as service } from '@ember/service';

export default Controller.extend({
  session: service(),
  currentUser: service('current-user'),

  actions: {
    logout() {
      this.session.invalidate();
    },

    login() {
      this.session.authenticate('authenticator:torii', 'github');
    }
  }

});
