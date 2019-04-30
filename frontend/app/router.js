import EmberRouter from "@ember/routing/router";
import config from "./config/environment";

const Router = EmberRouter.extend({
  location: config.locationType,
  rootURL: config.rootURL
});

Router.map(function() {
  this.route('index', { path: '/' });
  this.route('login');

  this.route('authenticated', { path: '' }, function() {
    this.route('index', { path: '/none' });

    this.route('repositories', function() {
      this.route('show', { path: '/:repository_id' });
    });
    this.route('builds', function() {
      this.route('show', { path: '/:build_id' }, function() {
        this.route('summary');
        this.route('artifacts');
        this.route('stream', { path: '/stream/:stream_id' }, function() {
          this.route('show', { path: '/' }, function() {
            this.route('box', { path: '/box/:box_id' });
            this.route('test_results', { path: '/test_results' });
          });
        });
      });
    });
    this.route('build_requests', function() {});
  })
});

export default Router;
