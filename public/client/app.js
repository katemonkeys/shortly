window.Shortly = Backbone.View.extend({

  template: _.template(' \
      <h1>Shortly</h1> \
      <div id="toplink"></div> \
      <div id="container"></div>'
  ),

      //   <div class="navigation"> \
      // <ul> \
      //   <li><a href="#" class="index">All Links</a></li> \
      //   <li><a href="#" class="create">Shorten</a></li> \
      // </ul> \
      // </div> \

  events: {
    "submit #toplink":  "this.renderIndexView"
    // "click li a.create": "renderIndexView"//,
    // "click li a.filter": "renderFilterView"
  },

  initialize: function(){
    console.log( "Shortly is running" );
    $('body').append(this.render().el);
    this.renderCreateView();
    this.renderIndexView(); // default view
  },

  render: function(){
    this.$el.html( this.template() );
    return this;
  },

  renderIndexView: function(e){
    e && e.preventDefault();
    var links = new Shortly.Links();
    var linksView = new Shortly.LinksView( {collection: links} );
    this.$el.find('#container').html( linksView.render().el );
    // this.updateNav('index');
  },

  renderCreateView: function(e){
    e && e.preventDefault();
    var linkCreateView = new Shortly.LinkCreateView();
    this.$el.find('#toplink').html( linkCreateView.render().el );
    // this.updateNav('create');
  }//,

  // renderFilterView: function(e){
  //   e && e.preventDefault();
  //   var filterCreateView = new Shortly.FilterView();
  //   this.$el.find('#container').html ( linksView.render().el );
  //   this.updateNav('filter');
  // },

  // updateNav: function(className){
  //   this.$el.find('.navigation li a')
  //           .removeClass('selected')
  //           .filter('.'+className)
  //           .addClass('selected');
  // }

});