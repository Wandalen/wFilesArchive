( function _Archive_s_() {

'use strict';

if( typeof module !== 'undefined' )
{

  var _global = _global_;
  var _ = _global_.wTools;

  require( '../FilesArchive.s' );

}

//

var _global = _global_;
var _ = _global_.wTools;
var Abstract = _.FileProvider.Abstract;
var Partial = _.FileProvider.Partial;
var Default = _.FileProvider.Default;
var Parent = Abstract;
var Self = function wFileFilterArchive( o )
{
  return _.instanceConstructor( Self, this, arguments );
}

Self.shortName = 'Archive';

// --
//
// --

function init( o )
{
  var self = this;

  _.assert( arguments.length <= 1 );
  _.instanceInit( self )
  Object.preventExtensions( self );

  if( o )
  self.copy( o );

  if( !self.original )
  self.original = _.fileProvider;

  var self = _.proxyMap( self, self.original );

  if( !self.archive )
  self.archive = new wFilesArchive({ fileProvider : self });

  return self;
}

// --
// relationship
// --

var Composes =
{
}

var Aggregates =
{
}

var Associates =
{
  archive : null,
  original : null,
}

var Restricts =
{
}

// --
// define class
// --

var Extend =
{

  init : init,

  // fileCopyAct : fileCopyAct,


  //

  
  Composes : Composes,
  Aggregates : Aggregates,
  Associates : Associates,
  Restricts : Restricts,

}

//

_.classDeclare
({
  cls : Self,
  parent : Parent,
  extend : Extend,
});

_.Copyable.mixin( Self );

//

_.FileFilter = _.FileFilter || Object.create( null );
_.FileFilter[ Self.shortName ] = Self;

// --
// export
// --

if( typeof module !== 'undefined' )
if( _global_.WTOOLS_PRIVATE )
delete require.cache[ module.id ];

if( typeof module !== 'undefined' && module !== null )
module[ 'exports' ] = Self;

})();
