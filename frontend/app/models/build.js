import DS from 'ember-data';
import { memberAction } from 'ember-api-actions';
import { computed } from '@ember/object';

export default DS.Model.extend({
  branch: DS.attr(),
  sha: DS.attr(),
  repository: DS.belongsTo('repository'),
  buildRequest: DS.belongsTo('build-request'),
  state: DS.attr(),
  hook_hash: DS.attr(),
  events: DS.attr('array'),
  triggerEvent: memberAction({ path: 'trigger_event' }),
  streams: DS.hasMany('streams'),

  active: computed('state', function() {
    if (this.get('state').endsWith('ing')) {
      return true;
    }

    return false;
  }),

  passed: computed('state', function() {
    if (this.get('state') == 'passed') {
      return true;
    }

    return false;
  }),
});
