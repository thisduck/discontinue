import Component from '@glimmer/component';
import { inject as service } from '@ember/service';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class BoxComponent extends Component {
  @service store;

  @tracked toggles = [];

  @action
  onToggle(index, f) {
    let t = this.toggles;
    t[index] = !t[index];
    this.toggles = t;
    f(t[index]);
  }
}
