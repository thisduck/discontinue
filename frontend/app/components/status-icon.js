import Component from '@glimmer/component';

export default class StatusIconComponent extends Component {
  get icon() {
    const { status } = this.args;
    const style = {
      'active': 'wifi',
      'passed': 'checkmark-circle-outline',
      'failed': 'close-circle-outline',
      'pending': 'code-working',
    }

    return style[status];
  }

  get spin() {
    const { status } = this.args;

    return status == 'active';
  }
}
