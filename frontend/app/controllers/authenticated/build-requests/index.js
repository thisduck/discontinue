import Controller from '@ember/controller';

export default class AuthenticatedBuildRequestsIndexController extends Controller {
  queryParams = {
    query: { refreshModel: true },
    page: { refreshModel: true },
    size: { refreshModel: true },
  }

  page = 1;
  size = 10;
}
