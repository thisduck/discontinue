import Route from '@ember/routing/route';

export default class AuthenticatedBuildRequestsIndexRoute extends Route {
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
  }
}