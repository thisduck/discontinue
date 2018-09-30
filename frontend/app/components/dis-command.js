import Component from '@ember/component';
import { computed } from '@ember/object';

export default Component.extend({
  tagName: '',
  color: computed('command.state', function() {

    if (this.get('command.state') == "passed") {
      return 'green'
    } else if (this.get('command.state') == "active") {
      return '';
    }

    return 'red';
  })

});
