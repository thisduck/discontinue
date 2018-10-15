import DS from 'ember-data';

export default DS.Model.extend({
  status: DS.attr(),
  test_id: DS.attr(),
  test_type: DS.attr(),
  description: DS.attr(),
  file_path: DS.attr(),
  line_number: DS.attr(),
  exception: DS.attr(),
  duration: DS.attr(),
  stream: DS.belongsTo('stream'),
  box: DS.belongsTo('box'),
  artifacts: DS.hasMany('artifact'),
  build_id: DS.attr(),
});
