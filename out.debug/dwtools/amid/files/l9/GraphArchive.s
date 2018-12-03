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

  // if( self.delayedDeleting )
  // {
  //   self.fileProvider.onCallBegin = self.callBeginDelete;
  //   self.fileProvider.onCall = self.callDelete;
  // }

}

//

function callBeginDelete( op )
{
  if( op.routineName !== 'fileDeleteAct' )
  return op.args;
  let o2 = op.args[ 0 ];
  _.assert( op.args.length === 1 );
  _.assert( arguments.length === 1 );
  logger.log( op.routine.name, 'callBeginDelete', _.select( o2, op.writes ).join( ', ' ) );
  return op.args;
}

//

function callDelete( op )
{
  debugger;
  if( op.routineName !== 'fileDeleteAct' )
  return op.originalBody.apply( op.originalFileProvider, op.args );
  let o2 = op.args[ 0 ];

  _.assert( args.length === 1 );
  _.assert( arguments.length === 1 );

  debugger;
  logger.log( op.routine.name, 'callDelete', _.select( o2, op.writes ).join( ', ' ) );
  return op.originalBody.apply( op.originalFileProvider, op.args );
}

//

function callLog( op )
{
  if( !op.writes.length && !op.reads.length )
  return op.args;
  let o2 = op.args[ 0 ];

  _.assert( op.args.length === 1 );
  _.assert( arguments.length === 1 );

  if( op.reads.length )
  logger.log( op.routine.name, 'read', _.select( o2, op.reads ).join( ', ' ) );
  if( op.writes.length )
  logger.log( op.routine.name, 'write', _.select( o2, op.writes ).join( ', ' ) );
  return op.args;
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

  callBeginDelete,
  callDelete,
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
