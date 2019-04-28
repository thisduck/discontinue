import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

export default class CommandComponent extends Component {
  @tracked toggle;

  didReceiveAttrs () {
    this._super(...arguments);
    let t = this.args.toggles[this.args.index];
    this.toggle = t;
  }

  get returnStyle() {
    const { command } = this.args;

    const return_code = parseInt(command.return_code, 10);
    if (return_code  > 0) {
      return 'danger-6'
    } else if (return_code == 0) {
      return 'success-6'
    }

    return 'grey-4';
  }

  get color() {
    if (this.args.command.state == "passed") {
      return 'green'
    } else if (this.args.command.state == "active") {
      return '';
    }

    return 'red';
  }

  get activeClass() {
    if (this.toggle) {
      return 'active';
    }

    return '';
  }

  @action
  toggleCommand() {
    this.args.onToggle(this.index, (toggle) => {
      this.toggle = toggle;
    });
  }
}
