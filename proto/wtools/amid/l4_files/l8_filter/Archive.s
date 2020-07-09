( function _Archive_s_() {

'use strict';

let _global = _global_;
let _ = _global_.wTools;
let Abstract = _.FileProvider.Abstract;
let Partial = _.FileProvider.Partial;
let Default = _.FileProvider.Default;
let Parent = Abstract;
let Self = wFileFilterArchive;
function wFileFilterArchive( o )
{
  return _.workpiece.construct( Self, this, arguments );
}

Self.shortName = 'Archive';

// --
// implementtation
// --

function init( o )
{
  let self = this;

  _.assert( arguments.length <= 1 );
  _.workpiece.initFields( self )
  Object.preventExtensions( self );

  if( o )
  self.copy( o );

  if( !self.original )
  self.original = _.fileProvider;

  let proxy = _.proxyMap( self, self.original );

  if( !proxy.archive )
  proxy.archive = new _.FilesArchive({ fileProvider : proxy });

  return proxy;
}

// --
// relationship
// --

let Composes =
{
}

let Aggregates =
{
}

let Associates =
{
  archive : null,
  original : null,
}

let Restricts =
{
}

// --
// declare
// --

let Extend =
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
module[ 'exports' ] = Self;

})();
