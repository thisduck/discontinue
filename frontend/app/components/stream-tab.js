import Component from '@glimmer/component';

export default class StreamTabComponent extends Component {

  get style() {
    const { stream } = this.args;
    const style = {
      'active': 'accent',
      'passed': 'success',
      'failed': 'danger',
    }

    return style[stream.get('status')];
  }
}
