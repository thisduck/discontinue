import DS from 'ember-data';
const { Model, attr, belongsTo, hasMany } = DS;

export default class StreamModel extends Model {
  @attr() name;
  @attr() state;
  @attr() buildId;
  @attr() humanized_time;
  @attr('date') started_at;
  @attr('date') finished_at;

  @belongsTo('build') build;

  @hasMany('box') boxes;
  // testResults: DS.hasMany('test-result'),

  get active() {
    // if (!this.get('build.active')) {
    //   return false;
    // }

    return this.state.endsWith('ing');
  }

  get passed() {
    return this.state == 'passed';
  }

  get status() {
    if (this.active) {
      return 'active';
    }

    if (this.passed) {
      return 'passed';
    }

    return 'failed';
  }
}
