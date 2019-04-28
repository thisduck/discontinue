import Route from '@ember/routing/route';

export default class AuthenticatedBuildsShowStreamShowRoute extends Route {
  model() {
    let { stream_id } = this.paramsFor('authenticated.builds.show.stream');
    return this.store.findRecord('stream', stream_id, { include: 'boxes' })
  }
}
