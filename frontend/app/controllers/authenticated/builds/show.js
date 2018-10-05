import Controller from '@ember/controller';
import { task, timeout } from 'ember-concurrency';

export default Controller.extend({
  poll: task(function * () {
    while (true) {
      if (this.get('model.active')) {
        this.get('model.streams').reload();
      }
      yield timeout(3000);
    }
  }).on('init').enqueue(),
});
