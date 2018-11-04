import Route from '@ember/routing/route';
import { inject as service } from '@ember/service';

export default Route.extend({
  store: service(),

  queryParams: {
    query: { refreshModel: true },
    page: { refreshModel: true },
    size: { refreshModel: true },
  },

  model({ query, size, page }) {
    let filter = {};
    if (query) {
      filter['query'] = query
    }

    return this.store.query('build', {
      sort: '-created-at', 
      filter: filter,
      page: {
        size: size,
        number: page
      }
    })
  },
});
