import Route from '@ember/routing/route';
import ApplicationRouteMixin from 'ember-simple-auth/mixins/application-route-mixin';
import { inject as service } from '@ember/service';

export default class ApplicationRoute extends Route.extend(ApplicationRouteMixin) {
  @service session;
}
