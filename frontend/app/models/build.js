import DS from 'ember-data';
const { Model, attr, belongsTo, hasMany } = DS;

export default class BuildModel extends Model {
  @attr() branch;
  @attr() sha;
  @attr() state;
  @attr() hookHash;
  @attr() events;
  @attr() duration;
  @attr() pullRequest;
  @attr('date') createdAt;
  @attr('date') startedAt;
  @attr('date') finishedAt;

  @belongsTo('repository') repository;
  @belongsTo('build-request') buildRequest;
  @belongsTo('build-summary') buildSummary;

  triggerEvent(params) {
    const modelName = this.constructor.modelName;
    const adapter = this.store.adapterFor(this.constructor.modelName);
    const url = adapter.buildURL(modelName, this.id) + "/trigger_event";

    return adapter.ajax(url, "PUT", {data: params})
  }


  @hasMany('streams') streams;

  // buildTiming: DS.belongsTo('build-timing'),
  // profileSummary: DS.belongsTo('profile-summary'),

  // triggerEvent: memberAction({ path: 'trigger_event' }),
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

  get running() {
    return this.state.endsWith('ing');
  }

  get active() {
    return this.running;
  }

  get passed() {
    return this.state == 'passed';
  }

  get pullRequests() {
    if (this.pullRequest) {
      return this.pullRequest.split(',');
    }

    return [];
  }
}
