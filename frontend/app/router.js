import EmberRouter from '@ember/routing/router';
import config from './config/environment';

const Router = EmberRouter.extend({
  location: config.locationType,
  rootURL: config.rootURL
});

Router.map(function() {
  this.route('index', { path: '/' });
  this.route('login');
  this.route('authenticated', { path: '' }, function() {
    this.route('builds', function() { 
      this.route('index', { path: '/' });
      this.route('show', { path: '/:build_id' }, function() {
        this.route('summary');
        this.route('stream', { path: '/stream/:stream_id' }, function() {
          this.route('box', { path: '/box/:box_id' });
        });
        this.route('artifacts');
      });
    });
    this.route('build_requests', function() { });
    this.route('repositories', function() {
      this.route('new');
      this.route('index', { path: '/' });
      this.route('show', { path: '/:repository_id' });
    });
  });
});

export default Router;
