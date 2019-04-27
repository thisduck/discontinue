import Route from '@ember/routing/route';
import config from '../config/environment';

export default class LoginRoute extends Route {
  config = config.torii.providers['github-oauth2'];

}
