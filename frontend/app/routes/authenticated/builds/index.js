import Route from '@ember/routing/route';

export default class AuthenticatedBuildsIndexRoute extends Route {
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
  }
}
