import Component from '@ember/component';
import { computed } from '@ember/object';

export default Component.extend({
  tagName: '',
  tabClass: computed('stream.{passed,active}', function() {
    if (this.get('stream.active')) {
      return 'accent';
    }

    if (this.get('stream.passed')) {
      return 'success';
    } else {
      return 'danger';
    }

  })

});

