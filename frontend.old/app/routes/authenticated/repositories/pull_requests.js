import Route from '@ember/routing/route';
import { inject as service } from '@ember/service';
import RSVP from 'rsvp';

export default Route.extend({
  ajax: service(),
  store: service(),

  model({ repository_id }) {
    return RSVP.hash({
      pull_requests: this.ajax.request('/github/pull_requests?repository_id=' + repository_id),
      repository_id: repository_id
    });
  },

  actions: {
    build(pull, repository_id) {
      let build = this.store.createRecord('build-request', {});
      build.buildFromPull({repository_id: repository_id, number: pull.number}).then((data) => {
        this.transitionTo('authenticated.builds.show', data.build.id);
      });
    }
  }

});
