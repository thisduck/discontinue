import Component from '@glimmer/component';
import AnsiUp from 'ansi_up';

export default class ShellOutputComponent extends Component {
  get ansi_output() {
    var ansi_up = new AnsiUp;
    var html = ansi_up.ansi_to_html(this.args.output);
    return html;
  }
}
