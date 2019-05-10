import Component from '@glimmer/component';

export default class CardComponent extends Component {
  get borderColor() {
    return this.args.borderColor || "grey-2";
  }

  get borderTop() {
    return this.args.borderTop || "";
  }

  get width() {
    return this.args.width || "full";
  }

  get flexDirection() {
    return this.args.flexDirection || "row";
  }

  get border() {
    return (this.args.border ? `-${this.args.border}` : null) || "";
  }
}
