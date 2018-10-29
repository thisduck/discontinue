import Route from '@ember/routing/route';
import { inject as service } from '@ember/service';

export default Route.extend({
  ajax: service(),
  store: service(),

  model({ repository_id }) {
    return this.get('ajax').request('/github/pull_requests?repository_id=' + repository_id);
  },

  actions: {
    build(pull) {
      let build = this.get("store").createRecord('build-request', {});
      build.buildFromPull({repository_id: pull.head.repo.id, number: pull.number}).then((data) => {
        this.transitionTo('authenticated.builds.show', data.build.id);
      });
    }
  }

});
