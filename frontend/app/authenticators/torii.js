import ToriiAuthenticator from 'ember-simple-auth/authenticators/torii';
import { inject as service } from '@ember/service';

export default ToriiAuthenticator.extend({
  torii: service(),
  ajax: service(),

  authenticate() {
    const ajax = this.get('ajax');
    const tokenExchangeUri = "https://localhost:3000/session/github/callback"

    return this._super(...arguments).then((data) => {
      return ajax.request(tokenExchangeUri, {
        type: 'POST',
        crossDomain: true,
        dataType: 'json',
        contentType: 'application/json',
        data: JSON.stringify({
          code: data.authorizationCode
        })
      }).then( (response) => {
        return {
          access_token: JSON.parse(response).access_token,
          provider: data.provider
        };
      });
    });
  }

});
