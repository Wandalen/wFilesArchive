( function _AtchiveRecord_s_() {

'use strict';

let File;

if( typeof module !== 'undefined' )
{

  require( '../UseFilesArchive.s' );

}

//

let _global = _global_;
let _ = _global_.wTools;
let Parent = null;
let Self = function wArchiveRecord( o )
{
  return _.instanceConstructor( Self, this, arguments );
}

Self.shortName = 'ArchiveRecord';

// --
// inter
// --

function finit()
{
  let self = this;
  self.deleting = 0;
  self.deletingOptions = null;
  self.stat = null;
  _.Copyable.prototype.finit.apply( self, arguments );
}

//

function init( o )
{
  let self = this;

  _.instanceInit( self );

  if( o )
  {
    self.copy( o );
    if( o.absolute )
    self.absolute = o.absolute;
  }

  Object.preventExtensions( self );

  _.assert( _.strIs( self.absolute ) );
}

//

function hashGet()
{
  let self = this;

  self.hash = self.fileProvider.hashRead( self.absolute );

}

// --
//
// --

let Composes =
{
  deleting : 0,
  hash : null,
}

let Aggregates =
{
}

let Associates =
{
  deletingOptions : null,
  stat : null,
  fileProvider : null,
}

let Restricts =
{
  absolute : null,
}

let Medials =
{
  absolute : null,
}

let Statics =
{
}

let Forbids =
{
}

// --
// declare
// --

let Extend =
{

  finit,
  init,

  hashGet,

  //

  Composes,
  Aggregates,
  Associates,
  Restricts,
  Medials,
  Statics,
  Forbids,

}

//

_.classDeclare
({
  cls : Self,
  parent : Parent,
  extend : Extend,
});

_.Copyable.mixin( Self );

_[ Self.shortName ] = Self;

// --
// export
// --

// if( typeof module !== 'undefined' )
// if( _global_.WTOOLS_PRIVATE )
// { /* delete require.cache[ module.id ]; */ }

if( typeof module !== 'undefined' && module !== null )
module[ 'exports' ] = Self;

})();
