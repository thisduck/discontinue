import Route from '@ember/routing/route';

export default class AuthenticatedBuildsShowStreamShowIndexRoute extends Route {
  afterModel(model, transition) {
    if (model.active) {
      const box = model.boxes.find((x) => x.active);

      if (box) {
        this.transitionTo('authenticated.builds.show.stream.show.box', model.build, model, box);
      } else {
        this.transitionTo('authenticated.builds.show.stream.show.box', model.build, model, model.boxes.firstObject);
      }
      
    } else {
        this.transitionTo('authenticated.builds.show.stream.show.box', model.build, model, model.boxes.firstObject);
    }

  }
}
