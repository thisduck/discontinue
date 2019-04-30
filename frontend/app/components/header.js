import Component from '@glimmer/component';

export default class HeaderComponent extends Component {
  get level() {
    return this.args.level || "2";
  }

  get style() {
    return this.args.style || "grey";
  }
}
