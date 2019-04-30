import Component from '@glimmer/component';

export default class StreamSummaryComponent extends Component {
  get style() {
    const { stream } = this.args;
    const style = {
      'active': 'accent',
      'passed': 'success',
      'failed': 'danger',
    }

    return style[stream.status];
  }

  get statusIcon() {
    const { stream } = this.args;
    const style = {
      'active': 'accent',
      'passed': 'checkmark-circle-outline',
      'failed': 'close-circle-outline',
    }

    return style[stream.status];
  }

  get summary() {
    const { stream } = this.args;

    const buildSummary = stream.get('build.buildSummary.results');

    return buildSummary[stream.id];
  }
}
