import LinkComponent from '@ember/routing/link-component';
import { computed, get } from '@ember/object';

export default LinkComponent.extend({
  inactiveClass: 'inactive',
  classNameBindings: ['inactive', 'active', 'loading', 'disabled', 'transitioningIn', 'transitioningOut'],

  inactive: computed('inactiveClass', '_active', function() {
    return !this.get('_active') ? get(this, 'inactiveClass') : false;
  }),
});
