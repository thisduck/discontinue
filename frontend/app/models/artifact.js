import DS from 'ember-data';
const { Model, attr, belongsTo } = DS;

export default class ArtifactModel extends Model {
  @attr() key;
  @attr() filename;
  @attr() extension;
  @attr() size;
  @attr() presignedUrl;

  @belongsTo('box') box;
}
