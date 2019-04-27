import Controller from '@ember/controller';

export default Controller.extend({
  queryParams: ['query', 'page', 'size'],
  query: '',
  page: 1,
  size: 10
});
