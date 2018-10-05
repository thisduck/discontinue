import Route from '@ember/routing/route';
import { inject as service } from '@ember/service';

export default Route.extend({
  store: service(),

  queryParams: {
    branch: { refreshModel: true }
  },

  model({ branch }) {
    let filter = {};
    if (branch) {
      filter['branch'] = branch
    }

    return this.store.query('build-request', {
      sort: '-created-at', 
      filter: filter,
      page: {
        size: 10,
        number: 1
      }
    })
  },
});
