import DS from 'ember-data';
import { computed } from '@ember/object';

export default DS.Model.extend({
  // output: DS.attr(),
  state: DS.attr(),
  stream: DS.belongsTo('stream'),
  commands: DS.hasMany('command'),
  testResults: DS.hasMany('test-result'),
  started_at: DS.attr('date'),
  finished_at: DS.attr('date'),
  humanized_time: DS.attr(),

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
