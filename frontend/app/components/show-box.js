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
      yield timeout(5000);
      if (this.get('box')) {
        this.get('box.commands').reload();
        if (!this.get('box.active')) {
          break;
        }
      }
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
