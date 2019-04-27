module.exports = function(env) {
  return {
    clientAllowedKeys: ['GITHUB_APP_CLIENT_ID'],
    // Fail build when there is missing any of clientAllowedKeys environment variables.
    // By default false.
    failOnMissingKey: false, 
  };
};
