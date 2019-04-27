import DS from 'ember-data';
import { computed } from '@ember/object';

export default DS.Model.extend({
  results: DS.attr(),

  display: computed('results', function() {
    let results = []
    this.results.forEach((result) => {
      result.stream = this.store.findRecord("stream", result.stream_id);
      results.push(result)
    })

    return results;
  }),
});
