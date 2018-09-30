import DS from 'ember-data';
import { isArray, A } from '@ember/array';

export default DS.Transform.extend({
  deserialize: function(serialized) {
    if (isArray(serialized)) {
      return A(serialized);
    } else {
      return A();
    }
  },

  serialize: function(deserialized) {
    if (isArray(deserialized)) {
      return A(deserialized);
    } else {
      return A();
    }
  }
});
