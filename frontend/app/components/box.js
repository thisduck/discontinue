import Component from '@glimmer/component';
import { inject as service } from '@ember/service';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { dropTask } from 'ember-concurrency-decorators';
import { timeout } from 'ember-concurrency';

export default class BoxComponent extends Component {
  @service store;

  @tracked toggles = [];

  constructor() {
    super(...arguments);
    this.poll.perform();
  }

  @action
  onToggle(index, f) {
    let t = this.toggles;
    t[index] = !t[index];
    this.toggles = t;
    f(t[index]);
  }

  @dropTask
  poll = function * () {
    if (!this.args.box.active) {
      return;
    }

    while (true) {
      yield timeout(5000);
      this.args.box.commands.reload();
      // if (!this.args.box.active) {
      //   let build = this.store.peekRecord('build', this.args.box.stream.buildId);
      //   build.reloadSummary();
      //   break;
      // }
    }

  }
}
