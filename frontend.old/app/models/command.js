import DS from 'ember-data';
import { computed } from '@ember/object';

export default DS.Model.extend({
  command: DS.attr(),
  lines: DS.attr(),
  state: DS.attr(),
  box: DS.belongsTo('box'),
  started_at: DS.attr('date'),
  finished_at: DS.attr('date'),
  humanized_time: DS.attr(),

  active: computed('state', function() {
    if (this.state.endsWith('ing')) {
      return true;
    }

    return false;
  }),

  passed: computed('state', function() {
    if (this.state == 'passed') {
      return true;
    }

    return false;
  }),

});
