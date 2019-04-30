import DS from 'ember-data';
const { Model, attr } = DS;

export default class StreamSummaryModel extends Model {
  @attr() results;
}
