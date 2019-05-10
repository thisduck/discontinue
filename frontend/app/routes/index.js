import Route from '@ember/routing/route';
import RSVP from 'rsvp';
import AuthenticatedRouteMixin from 'ember-simple-auth/mixins/authenticated-route-mixin';


export default class IndexRoute extends Route.extend(AuthenticatedRouteMixin) {
  model() {
    const adapter = this.store.adapterFor('build');
    return RSVP.hash({
      buildStatus: adapter.ajax('/api/reports/build_status'),
      mostFailed: adapter.ajax('/api/reports/most_failed'),
    });
  }
}
