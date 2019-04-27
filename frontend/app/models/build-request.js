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
