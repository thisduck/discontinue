import DS from 'ember-data';

export default DS.Model.extend({
  email: DS.attr(),
  github_login: DS.attr(),
  github_avatar_url: DS.attr(),
});
