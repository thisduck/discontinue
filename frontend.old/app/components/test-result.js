import Component from '@ember/component';

export default Component.extend({
  tagName: '',
  showMore: false,
  actions: {
    toggleMore() {
      this.toggleProperty('showMore');
    }
  }
});
