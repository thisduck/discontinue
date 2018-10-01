import Component from '@ember/component';
import { computed } from '@ember/object';

export default Component.extend({
  tagName: '',
  didReceiveAttrs () {
    this._super(...arguments);
    let t = this.get('toggles')[this.get('index')];
    this.set("toggle", t);
  },
  color: computed('command.state', function() {

    if (this.get('command.state') == "passed") {
      return 'green'
    } else if (this.get('command.state') == "active") {
      return '';
    }

    return 'red';
  }),
  activeClass: computed('toggle', function () {
    if (this.get('toggle')) {
      return 'active';
    }

    return '';
  }),
  actions: {
    toggleCommand() {
      this.onToggle(this.get('index'), (toggle) => {
        this.set('toggle', toggle);
      });
    }
  }

});
