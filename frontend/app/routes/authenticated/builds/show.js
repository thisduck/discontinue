import Route from '@ember/routing/route';
import { inject as service } from '@ember/service';

export default Route.extend({
  store: service(),

  model(params) {
    return this.store.findRecord('build', params.build_id)
  },
});
