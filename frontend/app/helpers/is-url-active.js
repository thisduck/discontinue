// from https://balinterdi.com/blog/a-lighter-weight-implementation-of-link-to/
import Helper from '@ember/component/helper';
import { inject as service } from '@ember/service';
import { observer } from '@ember/object';

export default Helper.extend({
  router:  service(),

  compute(params) {
    return this.get('router').isActive(...params);
  },

  onURLChange: observer('router.currentURL', function() {
    this.recompute();
  }),
});
