import Route from '@ember/routing/route';
import { inject as service } from '@ember/service';

export default Route.extend({
  store: service(),

  queryParams: {
    query: { refreshModel: true },
    page: { refreshModel: true },
    size: { refreshModel: true },
  },

  model({ query, page, size }) {
    let filter = {};
    if (query) {
      filter['query'] = query
    }

    return this.store.query('build-request', {
      sort: '-created-at', 
      filter: filter,
      page: {
        size: size,
        number: page
      }
    })
  },
});
