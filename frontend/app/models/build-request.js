import DS from 'ember-data';
import { memberAction, collectionAction } from 'ember-api-actions';
import { computed } from '@ember/object';

export default DS.Model.extend({
  branch: DS.attr(),
  sha: DS.attr(),
  repository: DS.belongsTo('repository'),
  state: DS.attr(),
  hookHash: DS.attr(),
  events: DS.attr('array'),
  triggerEvent: memberAction({ path: 'trigger_event' }),
  buildFromPull: collectionAction({path: 'build_from_pull', type: 'PUT'}),
  buildFromBranch: collectionAction({path: 'build_from_branch', type: 'PUT'}),
  lastBuild: DS.belongsTo('build'),

  active: computed(function() {
    return true;
  }),

  commitUrl: computed('hookHash', function() {
    return this.get('hookHash.head_commit.url')
  }),

  commitMessage: computed('hookHash', function() {
    return this.get('hookHash.head_commit.message')
  }),

  author: computed('hookHash', function() {
    return this.get('hookHash.head_commit.author.username')
  }),

  shortSha: computed('sha', function() {
    return this.sha.slice(0, 8);
  }),

});
