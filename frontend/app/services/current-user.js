import Service, { inject as service } from '@ember/service';

export default class CurrentUserService extends Service {
  @service session;
  @service store;

  load() {
    this.store.findRecord('user', 'current')
      .then((user) => {
        this.set('user', user);
      })
      .catch(() => {
        this.session.invalidate();
      });
  }
}
