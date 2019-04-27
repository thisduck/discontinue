import Component from '@ember/component';
import { computed } from '@ember/object';

export default Component.extend({
  tagName: '',
  color: computed('build.state', function() {

    if (this.get('build.state') == "passed") {
      return 'success'
    } else if (this.get('build.running')) {
      return 'accent';
    } else if (this.get('build.active')) {
      return 'primary';
    }

    return 'danger';
  }),

  actions: {
    triggerEvent(event) {
      this.build.triggerEvent({event: event}).then(() => {
        this.build.reload().then(() => {
          this.build.eachRelationship((name, {kind}) => {
            if (this.build[kind](name).value()) {
              this.build.get(name).reload();
            }
          })
        });
      });
    }
  }
});
