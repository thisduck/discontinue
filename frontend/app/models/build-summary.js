import DS from 'ember-data';
const { Model, attr } = DS;

export default class BuildSummaryModel extends Model {
  @attr() results;
}
