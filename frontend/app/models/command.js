import DS from 'ember-data';
const { Model, attr, belongsTo } = DS;

export default class CommandModel extends Model {
  @attr() command;
  @attr() lines;
  @attr() state;
  @attr() humanized_time;
  @attr() return_code;
  @attr('date') startedAt;
  @attr('date') finishedAt;

  @belongsTo('box') box;

  get active() {
    return this.state.endsWith('ing');
  }

  get passed() {
    return this.state == 'passed';
  }
}
