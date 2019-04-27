import Controller from '@ember/controller';
import { inject as service } from '@ember/service';
import { action } from '@ember/object';

export default class ApplicationController extends Controller {
  @service session;
  @service currentUser;

  @action
  logout() {
    this.session.invalidate();
  }

  @action
  login() {
    this.session.authenticate('authenticator:torii', 'github');
  }
}
