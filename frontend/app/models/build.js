import DS from 'ember-data';
import { memberAction } from 'ember-api-actions';
import { computed } from '@ember/object';

export default DS.Model.extend({

  branch: DS.attr(),
  sha: DS.attr(),
  repository: DS.belongsTo('repository'),
  buildRequest: DS.belongsTo('build-request'),
  state: DS.attr(),
  hookHash: DS.attr(),
  buildSummary: DS.belongsTo('build-summary'),
  buildTiming: DS.belongsTo('build-timing'),
  profileSummary: DS.belongsTo('profile-summary'),
  events: DS.attr('array'),
  triggerEvent: memberAction({ path: 'trigger_event' }),
  streams: DS.hasMany('streams'),
  startedAt: DS.attr('datetime'),

  active: computed('state', function() {
    if (this.state.endsWith('ing')) {
      return true;
    }

    return false;
  }),

  passed: computed('state', function() {
    if (this.state == 'passed') {
      return true;
    }

    return false;
  }),

  commitUrl: computed('hookHash', function() {
    return this.get('hookHash.head_commit.html_url') ||
      this.get('hookHash.head_commit.url')
  }),

  commitMessage: computed('hookHash', function() {
    return this.get('hookHash.head_commit.message')
  }),

  author: computed('hookHash', function() {
    return this.get('hookHash.head_commit.author.username') ||
      this.get('hookHash.head_commit.author.name');
  }),

  shortSha: computed('sha', function() {
    return this.sha.slice(0, 8);
  }),

  reloadSummary() {
    this.buildSummary.reload();
    this.buildTiming.reload();
    this.profileSummary.reload();
  }
});
