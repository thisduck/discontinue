import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

export default class TestResultComponent extends Component {
  @tracked showMore;

  get moreIcon() {
    if (this.showMore) {
      return 'arrow-dropdown';
    }

    return 'arrow-dropright';
  }

  @action
  toggleMore(event) {
    event && event.stopPropagation();
    this.showMore = !this.showMore;
  }

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
