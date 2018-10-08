import Component from '@ember/component';

export default Component.extend({
  tagName: '',
  showException: false,
  actions: {
    toggleException() {
      this.toggleProperty('showException');
    }
  }
});
