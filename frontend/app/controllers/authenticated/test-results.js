import Controller from '@ember/controller';

export default class AuthenticatedTestResultsController extends Controller {
  queryParams = {
    status: { refreshModel: true },
    test_id: { refreshModel: true },
    page: { refreshModel: true },
    size: { refreshModel: true },
  }

  page = 1;
  size = 15;
}
