import Component from '@ember/component';
import { on } from '@ember/object/evented';
import { next } from '@ember/runloop';
import ClickOutsideMixin from 'ember-click-outside/mixin';

export default Component.extend(ClickOutsideMixin, {
  tagName: 'span',
  show: false,

  clickOutside(e) {
    this.set("show", false);
  },

  actions: {
    toggleShow() {
      this.toggleProperty("show");
    },

    selectItem(item) {
      this.set("show", false);
      if (this.itemSelected) {
        this.itemSelected(item);
      }
    }
  },

  _attachClickOutsideHandler: on('didInsertElement', function() {
    next(this, this.addClickOutsideListener);
  }),

  _removeClickOutsideHandler: on('willDestroyElement', function() {
    this.removeClickOutsideListener();
  })
});
