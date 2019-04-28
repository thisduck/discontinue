import Component from '@glimmer/component';
import { action } from '@ember/object';

export default class ButtonComponent extends Component {

  get style() {
    return this.args.style || "primary";
  }

  get skin() {
    return this.args.skin || "primary";
  }

  get border() {
    if (this.skin == "link") {
      return false;
    }
    return true;
  }

  get textSize() {
    return this.args.size || "";
  }

  get textColor() {
    if (this.skin == "secondary" || this.skin == "link") {
      return `${this.style}-8`;
    }

    return 'grey-2';
  }

  get hoverTextColor() {
    if (this.skin == "secondary" || this.skin == "link") {
      return `${this.style}-5`;
    }

    return 'grey-1';
  }

  get bgColor() {
    if (this.skin == "secondary") {
      return 'grey-1';
    }

    if (this.skin == "link") {
      return false;
    }

    return `${this.style}-8`;
  }

  get hoverBgColor() {
    if (this.skin == "secondary") {
      return 'grey-1';
    }

    if (this.skin == "link") {
      return false;
    }

    return `${this.style}-5`;
  }

  get doAction() {
    return this.args.action || action(() => {});
  }
}
