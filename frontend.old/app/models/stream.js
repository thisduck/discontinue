import DS from 'ember-data';
import { computed } from '@ember/object';

export default DS.Model.extend({
  name: DS.attr(),
  state: DS.attr(),
  buildId: DS.attr(),
  build: DS.belongsTo('build'),
  boxes: DS.hasMany('box'),
  testResults: DS.hasMany('test-result'),
  started_at: DS.attr('date'),
  finished_at: DS.attr('date'),
  humanized_time: DS.attr(),

  active: computed('build.active', 'state', function() {
    if (!this.get('build.active')) {
      return false;
    }

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
