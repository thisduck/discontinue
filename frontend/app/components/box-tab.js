import Component from '@ember/component';
import { computed } from '@ember/object';

export default Component.extend({
  tagName: '',
  tabClass: computed('box.{passed,active}', function() {
    if (this.get('box.active')) {
      return '';
    }

    if (this.get('box.passed')) {
      return 'green';
    } else {
      return 'red';
    }

  })

});

