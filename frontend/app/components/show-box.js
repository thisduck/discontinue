import Component from '@ember/component';
import { task, timeout } from 'ember-concurrency';

export default Component.extend({
  tagName: '',

  didReceiveAttrs () {
    this._super(...arguments);
    this.set("toggles", []);
  },

  poll: task(function * () {
    while (true) {
      if (this.get('box.active')) {
        this.get('box.commands').reload();
      }
      yield timeout(3000);
    }
  }).on('init').enqueue(),

  actions: {
    onToggle(index, f) {
      let t = this.get('toggles');
      t[index] = !t[index];
      this.set('toggles', t)
      f(t[index]);
    }
  }

});
