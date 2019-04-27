import Service, { inject as service } from '@ember/service';

export default Service.extend({
  session: service(),
  store: service(),
  load() {
    this.get('store').findRecord('user', 'current')
      .then((user) => {
        this.set('user', user);
      })
      .catch(() => {
        this.get('session').invalidate();
      })
  }
});
