import Component from '@ember/component';
import { task, timeout } from 'ember-concurrency';
import { inject as service } from '@ember/service';

export default Component.extend({
  store: service(),
  tagName: '',

  didReceiveAttrs () {
    this._super(...arguments);
    this.set("toggles", []);
  },

  poll: task(function * () {
    if (!this.get('box.active')) {
      return;
    }

    while (true) {
      yield timeout(5000);
      this.get('box.commands').reload();
      if (!this.get('box.active')) {
        let build = this.store.peekRecord('build', this.get('box.stream.buildId'));
        build.reloadSummary();
        break;
      }
    }
  }).on('init').enqueue(),

  actions: {
    onToggle(index, f) {
      let t = this.toggles;
      t[index] = !t[index];
      this.set('toggles', t)
      f(t[index]);
    }
  }

});
