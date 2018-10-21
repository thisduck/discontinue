import Route from '@ember/routing/route';
import { task, timeout } from 'ember-concurrency';

export default Route.extend({
  model() {
    let { stream_id } = this.paramsFor('authenticated.builds.show.stream');
    return this.store.findRecord('stream', stream_id, { include: 'boxes' })

  },

  setupController(controller, model) {
    this._super(...arguments);
    if (model.get('active')) {
      this.get('poll').perform(model.id);
    }
  },

  poll: task(function * (id) {
    while (true) {
      yield timeout(5000);

      yield this.refresh();
      let model = this.store.peekRecord('stream', id);
      if (!model.get('active')) {
        let build = this.store.peekRecord('build', model.get('buildId'));
        build.reloadSummary();
        break;
      }
    }
  }).cancelOn('deactivate').restartable(),
});
