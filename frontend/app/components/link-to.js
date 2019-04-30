import LinkComponent from '@ember/routing/link-component';
import { computed, get } from '@ember/object';

export default LinkComponent.extend({
  inactiveClass: 'inactive',
  classNameBindings: ['inactive', 'active', 'loading', 'disabled', 'transitioningIn', 'transitioningOut', 'defaultClasses'],

  defaultClasses: computed(
    function() {
      return 'no-underline text-primary-8';
    }
  ),

  inactive: computed('inactiveClass', '_active', function() {
    return !this.get('_active') ? get(this, 'inactiveClass') : false;
  }),
});
