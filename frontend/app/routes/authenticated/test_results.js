import Route from '@ember/routing/route';
import { inject as service } from '@ember/service';

export default Route.extend({
  store: service(),

  queryParams: {
    status: { refreshModel: true },
    test_id: { refreshModel: true },
  },

  model({ status, test_id }) {
    let filter = {};
    if (status) {
      filter['status'] = status;
    }

    if (test_id) {
      filter['test_id'] = test_id;
    }

    return this.store.query('test-result', {
      sort: '-created-at', 
      filter: filter,
      page: {
        size: 50,
        number: 1
      }
    })
  },
});
