import Route from '@ember/routing/route';
import ApplicationRouteMixin from 'ember-simple-auth/mixins/application-route-mixin';
import { inject as service } from '@ember/service';

export default Route.extend(ApplicationRouteMixin, {
  currentUser: service('current-user'),
  session: service(),

  beforeModel() {
    this._super(...arguments);
    if (this.get('session.isAuthenticated')) {
      this.get("currentUser").load();
    }
  },
});
