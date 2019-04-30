import Route from '@ember/routing/route';

export default class AuthenticatedBuildsShowStreamShowTestResultsRoute extends Route {
  queryParams = {
    status: { refreshModel: true },
    box_id: { refreshModel: true },
  }

  model({ status, box_id }) {
    let filter = {};
    if (status) {
      filter['status'] = status;
    }

    if (box_id) {
      filter['box-id'] = box_id;
    }
    let stream = this.modelFor('authenticated.builds.show.stream');
    filter['stream-id'] = stream.id;

    return this.store.query('test-result', {
      sort: '-duration', 
      filter: filter,
      page: {
        size: 50,
        number: 1
      }
    })
  }
}
