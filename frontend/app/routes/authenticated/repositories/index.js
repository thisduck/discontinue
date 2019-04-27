import Route from '@ember/routing/route';

export default class AuthenticatedRepositoriesIndexRoute extends Route {
  model() {
    return this.store.findAll('repository')
  }
}
