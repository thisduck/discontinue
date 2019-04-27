import DS from 'ember-data';
const { Model, attr } = DS;

export default class UserModel extends Model {
  @attr() email;
  @attr() integrationLogin;
  @attr() avatar_url;
}
