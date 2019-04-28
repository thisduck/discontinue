import Route from '@ember/routing/route';
import { enqueueTask } from 'ember-concurrency-decorators';
import { timeout } from 'ember-concurrency';

export default class AuthenticatedBuildsShowStreamShowRoute extends Route {
  model() {
    let { stream_id } = this.paramsFor('authenticated.builds.show.stream');
    return this.store.findRecord('stream', stream_id, { include: 'boxes' })
  }

  setupController(controller, model) {
    super.setupController(...arguments);
    if (model.active) {
      this.poll.perform(model.id);
    }
  }

  @enqueueTask
  poll = function * (id) {
    while (true) {
      yield timeout(5000);

      yield this.refresh();
      let model = this.store.peekRecord('stream', id);
      if (!model.active) {
        let build = this.store.peekRecord('build', model.buildId);
        // build.reloadSummary();
        break;
      }
    }
  }
}
