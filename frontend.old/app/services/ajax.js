import AjaxService from 'ember-ajax/services/ajax';
import { isPresent } from '@ember/utils';
import { inject as service } from '@ember/service';
import { computed } from '@ember/object';

export default AjaxService.extend({
  session: service(),
  headers: computed('session.data.authenticated', {
    get() {
      let { token } = this.get('session.data.authenticated');
      let headers = {};
      if (isPresent(token)) {
        headers['Authorization'] = `Bearer ${token}`;
      }

      return headers;
    }
  })

});

