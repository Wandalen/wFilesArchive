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
  _.assert( self.imageFileProvider instanceof _.FileProvider.Abstract );
  _.assert( self.imageFileProvider.onCallBegin === null );
  _.assert( self.imageFileProvider.onCallEnd === null );

  self.factory = new _.ArchiveRecordFactory
  ({
    imageFileProvider : self.imageFileProvider,
    originalFileProvider : self.imageFileProvider.originalFileProvider,
  });

  // self.records.filePath = self.records.filePath || Object.create( null );

  // self.imageFileProvider.onCallBegin = self.callLog;

  if( self.timelapseUsing )
  self.imageFileProvider.onCall = _.routineJoin( self, self.timelapseCall );

}

//

function originalCall( op )
{
  let o2 = op.args[ 0 ];
  if( op.reads.length )
  logger.log( 'original', op.routine.name, 'read', _.select( o2, op.reads ).join( ', ' ) );
  if( op.writes.length )
  logger.log( 'original', op.routine.name, 'write', _.select( o2, op.writes ).join( ', ' ) );
  op.result = op.originalBody.apply( op.image, op.args );
}

//

function timelapseCall( op )
{
  let self = this;
  let path = op.originalFileProvider.path;
  let o2 = op.args[ 0 ];

  _.assert( op.args.length === 1 );

  if( !self.timelapseMode )
  return self.originalCall( op );

  if( !op.writesPaths )
  op.writesPaths = _.arrayFlatten( _.mapVals( _.mapSelect( o2, op.writes ) ) );
  if( !op.readsPaths )
  op.readsPaths = _.arrayFlatten( _.mapVals( _.mapSelect( o2, op.reads ) ) );

  let writingRecords = self.factory.recordsSelect( op.writesPaths );
  // if( writingRecords.length )
  // debugger;
  // let writingRecords = _.mapVals( _.mapSelect( self.records.filePath, op.writesPaths ) ).filter( ( el ) => el !== undefined );
  // if( _.entityLength( writingRecords ) )
  // debugger;
  if( op.routineName === 'fileCopyAct' )
  debugger;
  if( op.routineName === 'fileWriteAct' )
  debugger;

  if( op.routineName === 'fileDeleteAct' )
  return self.timelapseCallDelete( op );
  else if( op.routineName === 'statReadAct' )
  return self.timelapseCallStatReadAct( op );
  else if( op.routineName === 'fileExistsAct' )
  return self.timelapseCallFileExistsAct( op );
  else if( op.routineName === 'dirMakeAct' )
  return self.timelapseCallDirMakeAct( op );
  else if( op.routineName === 'fileCopyAct' )
  return self.timelapseCopyAct( op );
  // else if( op.routineName === 'fileCopyAct' || op.routineName === 'fileRenameAct' || op.routineName === 'hardLinkAct' )
  // return self.timelapseCopyAct( op );

  if( writingRecords.length )
  throw _.err( 'No timlapse hook for wirting method', op.routineName );

  return self.originalCall( op );
}

//

function timelapseSingleHook_functor( onDelayed )
{

  return function hook( op )
  {
    let self = this;
    let path = op.originalFileProvider.path;
    let o2 = op.args[ 0 ];

    // if( o2.filePath === undefined )
    // return self.originalCall( op );

    _.assert( op.args.length === 1 );
    _.assert( arguments.length === 1 );
    _.assert( path.isAbsolute( o2.filePath ) );

    // if( !op.writesPaths )
    // op.writesPaths = _.arrayFlatten( null, _.select( o2, op.writes ) );
    // if( !op.readsPaths )
    // op.readsPaths = _.arrayFlatten( null, _.select( o2, op.reads ) );

    let arecord = self.factory.records.filePath[ o2.filePath ];
    if( arecord && arecord.deleting === 1 )
    {

      if( op.writesPaths.length )
      logger.log( 'after delay', op.routine.name, 'write', op.writesPaths.join( ', ' ) );
      if( op.readsPaths.length )
      logger.log( 'after delay', op.routine.name, 'read', op.readsPaths.join( ', ' ) );

      onDelayed.call( self, op, arecord );
      return;
    }

    return self.originalCall( op );
  }

}

//

function timelapseLinkingHook_functor( onDelayed )
{

  return function hook( op )
  {
    let self = this;
    let path = op.originalFileProvider.path;
    let o2 = op.args[ 0 ];

    // if( o2.srcPath === undefined )
    // return self.originalCall( op );

    _.assert( op.args.length === 1 );
    _.assert( arguments.length === 1 );
    _.assert( path.isAbsolute( o2.srcPath ) );
    _.assert( path.isAbsolute( o2.dstPath ) );

    // if( !op.writesPaths )
    // op.writesPaths = _.arrayFlatten( null, _.select( o2, op.writes ) );
    // if( !op.readsPaths )
    // op.readsPaths = _.arrayFlatten( null, _.select( o2, op.reads ) );

    let srcRecord = self.factory.records.filePath[ o2.srcPath ];
    let dstRecord = self.factory.records.filePath[ o2.dstPath ];

    if( op.writesPaths.length )
    logger.log( 'after delay', op.routine.name, 'write', op.writesPaths.join( ', ' ) );
    if( op.readsPaths.length )
    logger.log( 'after delay', op.routine.name, 'read', op.readsPaths.join( ', ' ) );

    if( ( srcRecord && srcRecord.deleting ) || ( dstRecord && dstRecord.deleting ) )
    return onDelayed.call( self, op, dstRecord, srcRecord );

    return self.originalCall( op );
  }

}

//

function timelapseCallDelete( op )
{
  let self = this;
  let path = op.originalFileProvider.path;
  let o2 = op.args[ 0 ];

  _.assert( op.routineName === 'fileDeleteAct' );
  _.assert( op.args.length === 1 );
  _.assert( arguments.length === 1 );

  let stat = op.originalFileProvider.statRead({ sync : 1, filePath : o2.filePath });
  if( !stat.isTerminal() && !stat.isDir() )
  return self.originalCall( op );

  logger.log( 'delaying', op.routine.name, _.select( o2, op.writes ).join( ', ' ) );

  let arecord = self.factory.record( o2.filePath );

  _.assert( path.isAbsolute( o2.filePath ) );

  // if( self.records.filePath[ o2.filePath ] === undefined )
  // self.records.filePath[ o2.filePath ] = new _.ArchiveRecord({ absolute : o2.filePath });
  // let arecord = self.records.filePath[ o2.filePath ];
  // arecord.fileProvider = op.image;

  arecord.stat = stat;
  arecord.deleting = 1;
  arecord.deletingOptions = o2;

  _.assert( arecord === self.factory.records.filePath[ o2.filePath ] );
  _.assert( arecord.factory === self.factory );
  // _.assert( arecord.fileProvider === op.image );

}

//

let timelapseCallStatReadAct = timelapseSingleHook_functor( function( op )
{
  let self = this;
  let o2 = op.args[ 0 ];

  // if( o2.filePath === '/dst' )
  // debugger;

  if( o2.throwing )
  throw _.err( 'File', o2.filePath, 'was deleted' );
  op.result = null;

});

//

let timelapseCallFileExistsAct = timelapseSingleHook_functor( function( op )
{
  let self = this;
  let o2 = op.args[ 0 ];

  op.result = false;
});

//

let timelapseCallDirMakeAct = timelapseSingleHook_functor( function( op, arecord )
{
  let self = this;
  let o2 = op.args[ 0 ];

  if( !arecord.stat.isDir() )
  {
    arecord.deletingOptions.sync = 1;
    op.originalFileProvider.fileDeleteAct( arecord.deletingOptions );
  }

  arecord.finit();
  // _.assert( self.records.filePath[ arecord.absolute ] === arecord );
  // delete self.records.filePath[ arecord.absolute ];

  return true;
});

//

let timelapseCopyAct = timelapseLinkingHook_functor( function( op, dstRecord, srcRecord )
{
  let self = this;
  let o2 = op.args[ 0 ];

  _.assert( _.strIs( o2.srcPath ) );
  _.assert( _.strIs( o2.dstPath ) );

  if( !dstRecord || o2.breakingDstHardLink )
  return self.originalCall( op );

  // return self.originalCall( op );

  let srcStat = op.originalFileProvider.statRead({ filePath : o2.srcPath, sync : 1 });

  debugger;

  let identical = true;
  if( identical && dstRecord.stat.size !== srcStat.size )
  identical = false;

  if( identical )
  {
    debugger;
    let dstHash = dstRecord.hashRead();
    let srcHash = op.originalFileProvider.hashRead({ sync : 1, filePath : o2.srcPath });
    if( !srcHash || srcHash !== dstHash )
    identical = false;
  }

  if( dstRecord )
  dstRecord.finit();

  if( !identical )
  return self.originalCall( op );

  _.assert( 0, 'not tested' );

  // // let filePaths = _.arrayFlatten( null, _.select( o2, op.writes ) );
  // // for( let p = 0 ; p < filePaths.length ; p++ )
  // // debugger;
  // for( let p = 0 ; p < op.writesPaths.length ; p++ )
  // {
  //   let filePath = op.writesPaths[ p ];
  //   // _.assert( path.isAbsolute( filePath ) );
  //   if( arecord && arecord.deleting === 1 )
  //   {
  //     logger.log( 'launch', op.routine.name, 'deleteAct', arecord.deletingOptions.filePath );
  //     // debugger; xxx
  //     // let r = op.originalFileProvider.fileDeleteAct( arecord.deletingOptions );
  //     // _.assert( !_.consequenceIs( op.result ) );
  //     // arecord.deleting = 2;
  //     // arecord.deletingOptions = null;
  //   }
  // }
  //
  // return self.originalCall( op );
});

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

  // if( op.routine.name === 'fileRenameAct' )
  // debugger;
  // if( o2.filePath === '/src/f1' )
  // debugger;

}

//

function timelapseBegin( o )
{
  let self = this;

  o = _.routineOptions( timelapseBegin, arguments );

  self.timelapseMode = 1;

  logger.log( 'Timelaps begin' );
}

timelapseBegin.defaults =
{
}

//

function timelapseEnd( o )
{
  let self = this;

  o = _.routineOptions( timelapseEnd, arguments );

  self.timelapseMode = 0;

  logger.log( 'Timelaps end' );
}

timelapseEnd.defaults =
{
}

//

function del( o )
{
  o = _.routineOptions( del, arguments );

  logger.log( 'del' );

  // records.

}

del.defaults =
{
}

// --
//
// --

let Composes =
{
  timelapseUsing : 1,
  timelapseMode : 0,
}

let Aggregates =
{
}

let Associates =
{
  factory : null,
  imageFileProvider : null,
  // records : _.define.ownInstanceOf( _.FileRecordFilter ),
}

let Restricts =
{
}

let Statics =
{
}

let Forbids =
{
  fileProvider : 'fileProvider',
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

  originalCall,

  // callBeginDelete,
  timelapseCall,
  timelapseSingleHook_functor,
  timelapseLinkingHook_functor,
  timelapseCallDelete,
  timelapseCallStatReadAct,
  timelapseCallFileExistsAct,
  timelapseCallDirMakeAct,
  timelapseCopyAct,

  callLog,

  timelapseBegin,
  timelapseEnd,
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
