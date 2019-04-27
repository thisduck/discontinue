'use strict';

module.exports = function(environment) {
  let ENV = {
    modulePrefix: 'frontend',
    environment,
    rootURL: '/',
    locationType: 'router-scroll',
    historySupportMiddleware: true,
    EmberENV: {
      FEATURES: {
        // Here you can enable experimental features on an ember canary build
        // e.g. EMBER_NATIVE_DECORATOR_SUPPORT: true
      },
      EXTEND_PROTOTYPES: {
        // Prevent Ember Data from overriding Date.parse.
        Date: false
      }
    },

    torii: {
      sessionServiceName: 'session',
      providers: {
        'github-oauth2': {
          apiKey: 'Iv1.700b34a31c99963f',
          scope: 'repo repo:status read:user read:org user:email',
        }
      }
    },

    'ember-simple-auth-token': {
      serverTokenEndpoint: '/session',
      refreshAccessTokens: false,
      authorizationHeaderName: 'Authorization', // Header name added to each API request
      authorizationPrefix: 'Bearer ', // Prefix added to each API request
    },

    APP: {
      // Here you can pass flags/options to your application instance
      // when it is created
    }
  };

  if (environment === 'development') {
    // ENV.APP.LOG_RESOLVER = true;
    // ENV.APP.LOG_ACTIVE_GENERATION = true;
    // ENV.APP.LOG_TRANSITIONS = true;
    // ENV.APP.LOG_TRANSITIONS_INTERNAL = true;
    // ENV.APP.LOG_VIEW_LOOKUPS = true;
  }

  if (environment === 'test') {
    // Testem prefers this...
    ENV.locationType = 'none';

    // keep test console output quieter
    ENV.APP.LOG_ACTIVE_GENERATION = false;
    ENV.APP.LOG_VIEW_LOOKUPS = false;

    ENV.APP.rootElement = '#ember-testing';
    ENV.APP.autoboot = false;
  }

  if (environment === 'production') {
    // here you can enable a production-specific feature
  }

  return ENV;
};
