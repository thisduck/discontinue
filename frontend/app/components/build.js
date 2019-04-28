import Component from '@glimmer/component';
import { action } from '@ember/object';

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

  @action
  triggerEvent(event) {
    const { build } = this.args; 
    build.triggerEvent({event: event}).then(() => {
      build.reload().then(() => {
        build.eachRelationship((name, {kind}) => {
          if (build[kind](name).value()) {
            build.get(name).reload();
          }
        })
      });
    });
  }
}
