import DS from 'ember-data';
const { Model, attr, belongsTo } = DS;

export default class BuildModel extends Model {
  @attr() branch;
  @attr() sha;
  @attr() state;
  @attr() hookHash;
  @attr() events;
  @attr() duration;
  @attr('date') createdAt;

  @belongsTo('repository') repository;
  // repository: DS.belongsTo('repository'),
  // buildSummary: DS.belongsTo('build-summary'),
  // buildTiming: DS.belongsTo('build-timing'),
  // profileSummary: DS.belongsTo('profile-summary'),
  // buildRequest: DS.belongsTo('build-request'),
  // streams: DS.hasMany('streams'),

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
}
