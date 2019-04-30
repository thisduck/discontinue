import Route from '@ember/routing/route';
import RSVP from 'rsvp';


export default class AuthenticatedBuildsShowSummaryRoute extends Route {
  model() {
    const build = this.modelFor("authenticated.builds.show");
    return RSVP.hash({
      build,
      buildSummary: build.get('buildSummary')
    });

  }
}
