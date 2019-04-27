import Component from '@glimmer/component';

export default class BuildComponent extends Component {
  get color() {
    const { build } = this.args; 
    if (build.state == "passed") {
      return 'success'
    } else if (build.running) {
      return 'accent';
    } else if (build.active) {
      return 'primary';
    }

    return 'danger';
  }
}
