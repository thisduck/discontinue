import Controller from '@ember/controller';

export default Controller.extend({
  actions: {
    save() {
      this.get('model').save();
    },

    addStreamConfig() {
      let config = {name: '', build_commands: '', box_count: 1};
      this.get('model.streamConfigs').pushObject(config);
    },

    removeStreamConfig(config) {
      this.get('model.streamConfigs').removeObject(config);
    }
  }
});
