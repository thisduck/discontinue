import DS from 'ember-data';
const { Model, attr, belongsTo, hasMany } = DS;

export default class TestResultModel extends Model {
  @attr() status;
  @attr() test_id;
  @attr() test_type;
  @attr() description;
  @attr() file_path;
  @attr() line_number;
  @attr() exception;
  @attr() duration;
  @attr() build_id;

  @belongsTo('stream') stream;
  @belongsTo('box') box;
  @hasMany('artifact') artifacts;
}
