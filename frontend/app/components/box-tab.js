import Component from '@ember/component';
import { computed } from '@ember/object';

export default Component.extend({
  tagName: '',
  tabClass: computed('box.{passed,active}', function() {
    if (this.get('box.active')) {
      return 'info';
    }

    if (this.get('box.passed')) {
      return 'success';
    } else {
      return 'danger';
    }

  })

});

