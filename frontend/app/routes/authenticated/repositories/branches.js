import Route from '@ember/routing/route';
import { inject as service } from '@ember/service';
import RSVP from 'rsvp';

export default Route.extend({
  ajax: service(),
  store: service(),

  model({ repository_id }) {
    return RSVP.hash({
      branches: this.ajax.request('/github/branches?repository_id=' + repository_id),
      repository_id: repository_id
    });

  },

  actions: {
    build(branch, repository_id) {
      let build = this.store.createRecord('build-request', {});
      build.buildFromBranch({repository_id: repository_id, branch: branch.name}).then((data) => {
        this.transitionTo('authenticated.builds.show', data.build.id);
      });
    }
  }

});
