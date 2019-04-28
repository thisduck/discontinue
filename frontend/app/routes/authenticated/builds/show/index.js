import Route from '@ember/routing/route';

export default class AuthenticatedBuildsShowIndexRoute extends Route {
  afterModel(model, transition) {
    if (model.active) {
      const stream = model.streams.find((x) => x.active);
      if (stream) {
        const box = stream.boxes.find((x) => x.active);

        if (box) {
          this.transitionTo('authenticated.builds.show.stream.show.box', model, stream, box);
        } else {
          this.transitionTo('authenticated.builds.show.stream.show', model, stream);

        }
      }
      
    } else {
      this.transitionTo('authenticated.builds.show.summary', model);
    }

  }

}
