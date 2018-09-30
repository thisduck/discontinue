import DS from 'ember-data';

export default DS.Model.extend({
  name: DS.attr(),
  github_id: DS.attr(),
  github_url: DS.attr(),
  setup_commands: DS.attr(),
});
