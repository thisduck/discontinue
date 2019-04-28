import Route from '@ember/routing/route';
import { dropTask } from 'ember-concurrency-decorators';
import { timeout } from 'ember-concurrency';

export default class AuthenticatedBuildsShowRoute extends Route {
  model(params) {
    return this.store.findRecord('build', params.build_id, { include: 'streams' })
  }

  setupController(controller, model) {
    super.setupController(...arguments);

    if (model.active) {
      this.poll.perform(model.id);
    }
  }

  @dropTask
  poll = function * (id) {
    yield timeout(500);
    while (true) {
      let model = this.store.peekRecord('build', id);
      model.reload().then(() => {
        let active_streams = model.streams.filter((stream) => stream.active).length;
        model.streams.reload().then(function() {
          let still_active = model.streams.filter((stream) => stream.active).length;
          if (active_streams != still_active) {
            // model.reloadSummary();
          }
        });
      });
      if (!model.active) {
        // model.reloadSummary();
        break;
      }
      yield timeout(5000);
    }
  }
}
