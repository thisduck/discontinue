import Route from '@ember/routing/route';
import { task, timeout } from 'ember-concurrency';

export default Route.extend({
  model() {
    return this.modelFor('authenticated.builds.show.stream');
  },

  setupController(controller, model) {
    this._super(...arguments);
    this.get('poll').perform(model.id);
  },

  poll: task(function * (id) {
    yield timeout(500);
    while (true) {
      yield timeout(5000);
      let model = this.store.peekRecord('stream', id);
      model.get('boxes').reload();
      if (!model.get('active')) {
        break;
      }
    }
  }).cancelOn('deactivate').restartable(),
});
