import Component from '@ember/component';

export default Component.extend({
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
