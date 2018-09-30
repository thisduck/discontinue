import DS from 'ember-data';


export default DS.Model.extend({
  name: DS.attr(),
  state: DS.attr(),
  buildRequest: DS.belongsTo('build-request'),
  started_at: DS.attr('date'),
  finished_at: DS.attr('date'),
});
