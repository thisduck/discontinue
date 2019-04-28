import Helper from '@ember/component/helper';
import { run } from '@ember/runloop';

export default class FormatCurrency extends Helper {
  compute([], { start, finish }) {
    this.clearTimeout();
    if (! finish) {
      finish = Date.now();
      this.timeout = setTimeout(() => {
        run(() => this.recompute());
      }, 1000);
    }

    let seconds = (finish - start) / 1000;
    if (seconds == 0) {
      return '0s';
    }

    return [
      {count: 60, name: 'seconds'},
      {count: 60, name: 'minutes'},
      {count: 24, name: 'hours'},
      {count: 1000, name: 'days'},
    ].map((item) => {
      if (seconds > 0) {
        const n = Math.round(seconds % item.count);
        seconds = Math.floor(seconds / item.count);
        return `${n}${item.name[0]}`
      }

      return null;
    }).filter((item) => item !== null).reverse().join(' ')
  }

  clearTimeout() {
    this.timeout && clearTimeout(this.timeout);
  }


  destroy() {
    this.clearTimeout();
    this._super(...arguments);
  }
}
