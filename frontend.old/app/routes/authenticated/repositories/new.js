import Route from '@ember/routing/route';
import { inject as service } from '@ember/service';

export default Route.extend({
  ajax: service(),
  store: service(),

  model() {
    return this.ajax.request('/github/repositories');
  },

  actions: {
    create({id, full_name, ssh_url}) {
      let repository = this.store.createRecord('repository', {
        name: full_name,
        github_id: id,
        github_url: ssh_url
      });
      repository.save().then(() => {
        this.transitionTo('authenticated.repositories.show', repository);
      });
    }
  }

});
