import DS from 'ember-data';

export default DS.Model.extend({
  key: DS.attr(),
  filename: DS.attr(),
  extension: DS.attr(),
  size: DS.attr(),
  presignedUrl: DS.attr(),
  box: DS.belongsTo('box'),
});
