// Generated by CoffeeScript 1.9.3
(function() {
  var americano;

  americano = require('americano-cozy');

  module.exports = {
    bookmark: {
      byDate: function(doc) {
        return emit(Date.parse(doc.created), doc);
      }
    }
  };

}).call(this);
