import Component from '@ember/component';
import { computed } from '@ember/object';

export default Component.extend({
  tagName: '',
  color: computed('build.state', function() {

    if (this.get('build.state') == "passed") {
      return 'success'
    } else if (this.get('build.active')) {
      return 'info';
    }

    return 'danger';
  }),

  actions: {
    triggerEvent(event) {
      this.get('build').triggerEvent({event: event}).then(() => {
        this.get('build').reload().then(() => {
          this.get('build').eachRelationship((name, {kind}) => {
            if (this.get('build')[kind](name).value()) {
              this.get('build').get(name).reload();
            }
          })
        });
      });
    }
  }
});
