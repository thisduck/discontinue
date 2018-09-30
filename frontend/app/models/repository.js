import DS from 'ember-data';
import { A } from '@ember/array';

export default DS.Model.extend({
  name: DS.attr(),
  github_id: DS.attr(),
  github_url: DS.attr(),
  setup_commands: DS.attr(),
  streamConfigs: DS.attr('array', { defaultValue() { return A(); } })
});
