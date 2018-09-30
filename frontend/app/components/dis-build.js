import Component from '@ember/component';

export default Component.extend({
  actions: {
    triggerEvent(event) {
      this.get('build').triggerEvent({event: event}).then(() => {
        this.get('build').reload();
      });
    }
  }
});
