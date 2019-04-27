import { module, test } from 'qunit';
import { setupTest } from 'ember-qunit';

module('Unit | Route | repositories/new', function(hooks) {
  setupTest(hooks);

  test('it exists', function(assert) {
    let route = this.owner.lookup('route:repositories/new');
    assert.ok(route);
  });
});
