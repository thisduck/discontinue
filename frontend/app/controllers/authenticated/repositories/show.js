import Controller from '@ember/controller';

export default Controller.extend({
  actions: {
    save() {
      this.get('model').save();
    },

    updateConfig(index, value) {
      this.set('model.streamConfigs.' + index, value);
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
