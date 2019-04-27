import Component from '@ember/component';
import { computed } from '@ember/object';
import AnsiUp from 'ansi_up';

export default Component.extend({
  tagName: '',
  didReceiveAttrs () {
    this._super(...arguments);
    let t = this.toggles[this.index];
    this.set("toggle", t);
  },
  ansi_lines: computed('command.lines', function() {
    var ansi_up = new AnsiUp;
    var html = ansi_up.ansi_to_html(this.get('command.lines'));
    return html;
    // return this.get('command.lines')
  }),
  color: computed('command.state', function() {

    if (this.get('command.state') == "passed") {
      return 'green'
    } else if (this.get('command.state') == "active") {
      return '';
    }

    return 'red';
  }),
  activeClass: computed('toggle', function () {
    if (this.toggle) {
      return 'active';
    }

    return '';
  }),
  actions: {
    toggleCommand() {
      this.onToggle(this.index, (toggle) => {
        this.set('toggle', toggle);
      });
    }
  }

});
