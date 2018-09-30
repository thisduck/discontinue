import Component from '@ember/component';
import { task, timeout } from 'ember-concurrency';

export default Component.extend({
  tagName: '',

  pollBox: task(function * () {
    while (true) {
      if (this.get('box.active')) {
        this.get('box').reload();
      }
      yield timeout(3000);
    }
  }).on('init').enqueue()

});
