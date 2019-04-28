import DS from 'ember-data';
const { Model, attr, belongsTo, hasMany } = DS;

export default class BoxModel extends Model {
  @attr() state;
  @attr() humanized_time;
  @attr() box_number;
  @attr('date') startedAt;
  @attr('date') finishedAt;

  @belongsTo('stream') stream;

  @hasMany('command') commands;
  // testResults: DS.hasMany('test-result'),
  // artifacts: DS.hasMany('artifact'),

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
