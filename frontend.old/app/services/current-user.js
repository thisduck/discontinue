import Service, { inject as service } from '@ember/service';

export default Service.extend({
  session: service(),
  store: service(),
  load() {
    this.store.findRecord('user', 'current')
      .then((user) => {
        this.set('user', user);
      })
      .catch(() => {
        this.session.invalidate();
      })
  }
});
