import Component from '@glimmer/component';

export default class StreamSummaryRowComponent extends Component {
  get style() {
    const { result } = this.args;
    const style = {
      'active': 'accent',
      'passed': 'success',
      'failed': 'danger',
      'pending': 'warning',
    }

    return style[result.status];
  }
}
