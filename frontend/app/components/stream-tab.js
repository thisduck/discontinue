import Component from '@ember/component';
import { computed } from '@ember/object';
import { task, timeout } from 'ember-concurrency';

export default Component.extend({
  tagName: '',
  poll: task(function * () {
    while (true) {
      if (this.get('stream.active')) {
        this.get('stream').reload();
      }
      yield timeout(3000);
    }
  }).on('init').enqueue(),
  tabClass: computed('stream.{passed,active}', function() {
    if (this.get('stream.active')) {
      return '';
    }

    if (this.get('stream.passed')) {
      return 'green';
    } else {
      return 'red';
    }

  })

});

