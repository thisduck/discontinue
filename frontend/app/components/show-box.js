import Component from '@ember/component';

export default Component.extend({
  tagName: '',

  didReceiveAttrs () {
    this._super(...arguments);
    this.set("toggles", []);
  },

  actions: {
    onToggle(index, f) {
      let t = this.get('toggles');
      t[index] = !t[index];
      this.set('toggles', t)
      f(t[index]);
    }
  }

});
