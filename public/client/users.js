//users.js

Shortly.Users = Backbone.Collection.extend({

  model: Shortly.User,
  url: '/users'

});