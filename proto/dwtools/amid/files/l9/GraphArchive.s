( function _GraphArchive_s_() {

'use strict';

//

let _global = _global_;
let _ = _global_.wTools;
let Parent = null;
let Self = function wFilesGraphArchive( o )
{
  _.assert( arguments.length === 0 || arguments.length === 1, 'Expects single argument' );
  return _.instanceConstructor( Self, this, arguments );
}

Self.shortName = 'FilesGraphArchive';

// --
// inter
// --

function init( o )
{
  let self = this;

  _.assert( arguments.length === 0 || arguments.length === 1 );

  _.instanceInit( self );
  Object.preventExtensions( self )

  if( o )
  self.copy( o );

  self.form();

}

//

function form()
{
  let self = this;

  _.assert( arguments.length === 0 );
  _.assert( self.fileProvider instanceof _.FileProvider.Abstract );
  _.assert( self.fileProvider.onCallBegin === null );
  _.assert( self.fileProvider.onCallEnd === null );

  self.fileProvider.onCallBegin = self.callLog;

  if( self.delayedDeleting )
  {
    debugger;
    x
  }

}

//

function callDelete( args, op )
{
  if( op.routineName !== 'fileDeleteAct' )
  return;
  let o = args[ 0 ];
  _.assert( args.length === 1 );

  xxx

  return args;
}

//

function callBeginDelete( args, op )
{
  if( op.routineName !== 'fileDeleteAct' )
  return;
  let o = args[ 0 ];
  _.assert( args.length === 1 );

  xxx

  return args;
}

//

function callLog( args, op )
{
  if( !op.writes.length && !op.reads.length )
  return args;
  let o = args[ 0 ];
  _.assert( args.length === 1 );
  if( op.reads.length )
  console.log( op.routine.name, 'read', _.select( o, op.reads ).join( ', ' ) );
  if( op.writes.length )
  console.log( op.routine.name, 'write', _.select( o, op.writes ).join( ', ' ) );
  return args;
}

//

function begin( o )
{
  o = _.routineOptions( begin, arguments );

  logger.log( 'begin' );

}

begin.defaults =
{
}

//

function end( o )
{
  o = _.routineOptions( end, arguments );

  logger.log( 'end' );

}

end.defaults =
{
}

//

function del( o )
{
  o = _.routineOptions( del, arguments );

  logger.log( 'del' );

  // files.

}

del.defaults =
{
}

// --
//
// --

let Composes =
{
  delayedDeleting : 1,
}

let Aggregates =
{
}

let Associates =
{
  fileProvider : null,
  files : _.define.ownInstanceOf( _.FileRecordFilter ),
}

let Restricts =
{
}

let Statics =
{
}

let Forbids =
{
}

let Accessors =
{
}

// --
// declare
// --

let Proto =
{

  init,
  form,

  callDelete,
  callBeginDelete,
  callLog,

  begin,
  end,
  del,

  //

  Composes,
  Aggregates,
  Associates,
  Restricts,
  Statics,
  Forbids,
  Accessors,

}

//

_.classDeclare
({
  cls : Self,
  parent : Parent,
  extend : Proto,
});

//

_.Copyable.mixin( Self );
_.StateStorage.mixin( Self );

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
