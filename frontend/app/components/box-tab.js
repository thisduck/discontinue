import Component from '@glimmer/component';

export default class BoxTabComponent extends Component {
  get style() {
    const { box } = this.args;
    const style = {
      'active': 'accent',
      'passed': 'success',
      'failed': 'danger',
    }

    return style[box.get('status')];
  }
}
