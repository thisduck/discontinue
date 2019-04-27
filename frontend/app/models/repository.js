import DS from 'ember-data';
const { Model, attr } = DS;

export default class RepositoryModel extends Model {
  @attr() name;
  @attr() fullName;
  @attr() integrationId;
  @attr() url;
  @attr() config;
  @attr() streamConfigs;
}
