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
    this.route('test_results', function() { });
    this.route('builds', function() { 
      this.route('index', { path: '/' });
      this.route('show', { path: '/:build_id' }, function() {
        this.route('summary');
        this.route('stream', { path: '/stream/:stream_id' }, function() {
          this.route('show', { path: '/' }, function() {
            this.route('box', { path: '/box/:box_id' });
          });
          this.route('test_results', { path: '/test_results' });
        });
        this.route('artifacts');
      });
    });
    this.route('build_requests', function() { });
    this.route('repositories', function() {
      this.route('new');
      this.route('index', { path: '/' });
      this.route('show', { path: '/:repository_id' });
      this.route('pull_requests', { path: '/:repository_id/pull_requests' });
    });
  });
});

export default Router;
