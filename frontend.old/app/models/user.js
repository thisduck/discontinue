import DS from 'ember-data';

export default DS.Model.extend({
  email: DS.attr(),
  integrationLogin: DS.attr(),
  avatar_url: DS.attr(),
});
