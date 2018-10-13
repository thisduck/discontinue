import Route from '@ember/routing/route';
import { task, timeout } from 'ember-concurrency';
import { inject as service } from '@ember/service';

export default Route.extend({
  store: service(),

  model(params) {
    return this.store.findRecord('build', params.build_id, { include: 'streams' })
  },

  setupController(controller, model) {
    this._super(...arguments);
    this.get('poll').perform(model.id);
  },

  poll: task(function * (id) {
    yield timeout(500);
    while (true) {
      let model = this.store.peekRecord('build', id);
      model.reload().then(() => {
        model.get('streams').reload();
      });
      if (!model.get('active')) {
        break;
      }
      yield timeout(5000);
    }
  }).cancelOn('deactivate').restartable(),
});
