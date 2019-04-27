import DS from 'ember-data';
import { A } from '@ember/array';

export default DS.Model.extend({
  name: DS.attr(),
  fullName: DS.attr(),
  integrationId: DS.attr(),
  url: DS.attr(),
  config: DS.attr(),
  streamConfigs: DS.attr('array', { defaultValue() { return A(); } })
});
