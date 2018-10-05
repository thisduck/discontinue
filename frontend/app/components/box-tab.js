import Component from '@ember/component';
import { computed } from '@ember/object';
import { task, timeout } from 'ember-concurrency';

export default Component.extend({
  tagName: '',
  poll: task(function * () {
    while (true) {
      if (this.get('box.active')) {
        this.get('box').reload();
      }
      yield timeout(3000);
    }
  }).on('init').enqueue(),
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

