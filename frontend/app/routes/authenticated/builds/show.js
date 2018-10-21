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

    if (model.get('active')) {
      this.get('poll').perform(model.id);
    }
  },

  poll: task(function * (id) {
    yield timeout(500);
    while (true) {
      let model = this.store.peekRecord('build', id);
      model.reload().then(() => {
        let active_streams = model.get('streams').filter((stream) => stream.get("active")).length;
        model.get('streams').reload().then(function() {
          let still_active = model.get('streams').filter((stream) => stream.get("active")).length;
          if (active_streams != still_active) {
            model.reloadSummary();
          }
        });
      });
      if (!model.get('active')) {
        model.reloadSummary();
        break;
      }
      yield timeout(5000);
    }
  }).cancelOn('deactivate').restartable(),
});
