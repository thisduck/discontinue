import Route from '@ember/routing/route';
import { inject as service } from '@ember/service';

export default Route.extend({
  store: service(),

  queryParams: {
    status: { refreshModel: true }
  },

  model({ status }) {
    let filter = {};
    if (status) {
      filter['status'] = status;
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
  },
});
