import Route from '@ember/routing/route';
// import ResetQueryParams from 'ember-reset-query-params/mixins/reset-query-params';

export default class AuthenticatedTestResultsRoute extends Route {
  queryParams = {
    branch: { refreshModel: true },
    status: { refreshModel: true },
    test_id: { refreshModel: true },
    page: { refreshModel: true },
    size: { refreshModel: true },
  }

  model({ status, test_id, page, size, branch}) {
    let filter = {};
    if (status) {
      filter['status'] = status;
    }

    if (branch) {
      filter['branch'] = branch;
    }

    if (test_id) {
      filter['test_id'] = test_id;
    }

    return this.store.query('test-result', {
      sort: '-created-at', 
      filter: filter,
      page: {
        size: size,
        number: page
      }
    })
  }
}
