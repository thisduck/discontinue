import DS from 'ember-data';
const { Model, attr, belongsTo } = DS;

export default class BuildRequestModel extends Model {
  @attr() branch;
  @attr() sha;
  @attr() state;
  @attr() hookHash;
  @attr() events;
  @attr() duration;
  @attr('date') createdAt;

  @belongsTo('repository') repository;
  @belongsTo('build') lastBuild;

  triggerEvent(params) {
    const modelName = this.constructor.modelName;
    const adapter = this.store.adapterFor(this.constructor.modelName);
    const url = adapter.buildURL(modelName, this.id) + "/trigger_event";

    return adapter.ajax(url, "PUT", {data: params})
  }

  get active() {
    return true;
  }

  get shortSha() {
    return this.sha.slice(0, 8);
  }

  get commitUrl() {
    return this.get('hookHash.head_commit.html_url') ||
      this.get('hookHash.head_commit.url')
  }

  get author() {
    return this.get('hookHash.head_commit.author.username') ||
      this.get('hookHash.head_commit.author.login') ||
      this.get('hookHash.head_commit.author.name');
  }

  get commitMessage() {
    return this.get('hookHash.head_commit.message') ||
    this.get('hookHash.head_commit.commit.message');
  }
}
