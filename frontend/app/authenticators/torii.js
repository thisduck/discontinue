import ToriiAuthenticator from 'ember-simple-auth/authenticators/torii';
import { inject as service } from '@ember/service';

export default ToriiAuthenticator.extend({
  torii: service(),
  session: service(),

  restore(data) {
  },

  authenticate(/*args*/) {
    return this._super(...arguments).then((data) => {
      return this.session.authenticate('authenticator:token', {code: data.authorizationCode}).then(() => {
        // this.currentUser.load();
        return this.get('session.data.authenticated');
      });
    });
  },

  invalidate(data) {
  }
});
