import DS from 'ember-data';
import { memberAction } from 'ember-api-actions';


export default DS.Model.extend({
  branch: DS.attr(),
  sha: DS.attr(),
  repository: DS.belongsTo('repository'),
  state: DS.attr(),
  hook_hash: DS.attr(),
  events: DS.attr('array'),
  triggerEvent: memberAction({ path: 'trigger_event' }),
  lastBuild: DS.belongsTo('build'),
});