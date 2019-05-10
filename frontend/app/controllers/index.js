import Controller from '@ember/controller';

export default class IndexController extends Controller {
  data = [
    {
      name: "passed",
      x: [1, 2, 3, 4],
      y: [1, 2, 3, 4],
      type: "bar"
    },
    {
      name: "failed",
      x: [1, 2, 3, 4],
      y: [1, 2, 3, 4],
      type: "bar"
    }
  ]

  config = {
    displaylogo: false,
    responsive: true
  }

  layout = {
    title: 'Build status on master',
    barmode: 'stack',
    autosize: true,
   
  }
}
