( function _FilesGraph_s_() {

'use strict';

//

var _ = _global_.wTools;
var Parent = null;
var Self = function wFilesGraph( o )
{
  if( !( this instanceof Self ) )
  if( o instanceof Self )
  {
    _.assert( arguments.length === 1 );
    return o;
  }
  else
  return new( _.routineJoin( Self, Self, arguments ) );
  return Self.prototype.init.apply( this,arguments );
}

Self.nameShort = 'FilesGraph';

//

function init( o )
{
  var self = this;

  _.assert( arguments.length === 0 || arguments.length === 1 );

  _.instanceInit( self );
  Object.preventExtensions( self )

  if( o )
  self.copy( o );

}

//

// function contentUpdate( head,data )
// {
//   var self = this;
//
//   _.assert( arguments.length === 2 );
//
//   var head = _.FileRecord.from( head );
//   var dependency = self._headToTailsFor( head );
//
//   dependency.node.hash = self._hashFor( data );
//
//   return dependency;
// }
//
// //
//
// function statUpdate( head,stat )
// {
//   var self = this;
//
//   _.assert( arguments.length === 2 );
//
//   var head = _.FileRecord.from( head );
//   var dependency = self._headToTailsFor( head );
//
//   dependency.node.mtime = stat.mtime.getTime();
//   dependency.node.ctime = stat.ctime.getTime();
//   dependency.node.birthtime = stat.birthtime.getTime();
//   dependency.node.size = stat.size;
//
//   return dependency;
// }

// --
// iterator
// --

function _eachHeadPre( routine,args )
{
  var self = this;
  var result = 0;
  var op;

  if( args.length === 2 )
  op = { path : args[ 0 ], onUp : args[ 1 ] };
  else
  op = args[ 0 ];

  _.routineOptions( routine,op );
  _.assert( args.length === 1 || args.length === 2 );
  _.assert( _.pathIsAbsolute( op.path ) );
  _.assert( arguments.length === 2 );

  op.visited = op.visited || [];

  var path = op.path;

  delete op.path;

  op.operation = op;

  op.iterationNew = function iterationNew( path )
  {
    var it = Object.create( op.operation );
    it.prevPath = this.path || null;
    it.path = path;
    return it;
  }

  var it = op.iterationNew( path )

  return [ it,op ];
}

//

function _eachHeadBody( it,op )
{
  var self = this;
  var result = 1;

  _.assert( arguments.length === 2 );
  _.assert( self.nodesMap[ it.path ] );

  if( _.arrayHas( op.visited,it.path ) )
  return;

  op.visited.push( it.path )

  if( op.onUp )
  op.onUp( it,op );

  var dep = self.headsForTailMap[ it.path ];

  if( !dep )
  return result;

  for( var h in dep.heads )
  {
    result += self.eachHead.body.call( self,it.iterationNew( h ),op );
  }

  if( op.onDown )
  op.onDown( it,op );

  return result;
}

_eachHeadBody.defaults =
{
  onUp : null,
  onDown : null,
  visited : null,
}

//

function eachHead( o )
{
  var self = this;
  var args = self.eachHead.preArguments.call( self, self.eachHead, arguments );
  var result = self.eachHead.body.apply( self, args );
  return result;
}

eachHead.preArguments = _eachHeadPre;
eachHead.body = _eachHeadBody;

eachHead.defaults =
{
  path : null,
  onUp : null,
  onDown : null,
}

// --
// file
// --

function fileChange( path )
{
  var self = this;
  var result = 0;

  _.assert( arguments.length === 1 );
  _.assert( _.pathIsAbsolute( path ) );

  function onUp( it,op )
  {
    self.changedMap[ it.path ] = true;
    if( self.verbosity >= 3 )
    if( it.prevPath )
    logger.log( '. change',it.path,'by',it.prevPath );
    else
    logger.log( '. change',it.path );
  }

  var result = self.eachHead( path,onUp );
}

//

function filesUpdate( record )
{
  var self = this;

  _.assert( arguments.length === 1 );

  if( _.arrayIs( record ) )
  {
    for( var r = 0 ; r < record.length ; r++ )
    self.filesUpdate( record[ r ] );
    return self;
  }

  _.assert( record instanceof _.FileRecord );

  self._nodeForChanging( record )

  delete self.unprocessedMap[ record.absolute ];

  return self;
}

//

function fileDeletedUpdate( path )
{
  var self = this;

  _.assert( arguments.length === 1 );

  // self.eachHead
  // ({
  //   onUp : onUp,
  //   onDown : onDown,
  //   path : path,
  // });
  //
  // function onUp( it,op )
  // {
  // }
  //
  // function onDown( it,op )
  // {
  // }

  /* */

  var dep = self.tailsForHeadMap[ path ]
  if( dep )
  for( var t in dep.tails )
  {
    var tail = self.headsForTailMap[ t ];
    _.assert( tail );
    var head = tail.heads[ path ];
    _.assert( head );
    delete tail.heads[ path ]
  }

  /* */

  var dep = self.headsForTailMap[ path ]
  if( dep )
  for( var h in dep.heads )
  {
    debugger; xxx
    var head = self.tailsForHeadMap[ h ];
    _.assert( head );
    var tail = head.tails[ path ];
    _.assert( tail );
    delete head.tails[ path ]
  }

  /* */

  delete self.tailsForHeadMap[ path ];
  delete self.headsForTailMap[ path ];
  delete self.nodesMap[ path ];

}

//

function fileIsUpToDate( head )
{
  var self = this;

  _.assert( arguments.length === 1 );
  _.assert( head instanceof _.FileRecord );

  if( self.changedMap[ head.absolute ] )
  return false;

  return true;
}

//

function unprocessedDelete()
{
  var self = this;
  var fileProvider = self.fileProvider;

  _.assert( arguments.length === 0 );

  if( !self.unporcessedDstUnmapping )
  return;

  for( var n in self.unprocessedMap )
  {
    var node = self.unprocessedMap[ n ];

    if( _.strBegins( n,self.dstPath ) )
    {
      if( !self.unporcessedDstDeleting )
      fileProvider.fileDelete({ filePath : n, verbosity : self.verbosity });
    }

    delete self.unprocessedMap[ n ];
    self.fileDeletedUpdate( n );

  }

}

//

function unprocessedReport()
{
  var self = this;
  var fileProvider = self.fileProvider;

  _.assert( arguments.length === 0 );

  var unprocessedMapKeys = _.mapKeys( self.unprocessedMap );
  if( unprocessedMapKeys.length )
  {

    if( self.verbosity >= 4 )
    for( var n in self.unprocessedMap )
    {

      if( _.strBegins( n,self.dstPath ) )
      {
        logger.log( '? unprocessed dst',n );
      }
      else if( _.strBegins( n,self.srcPath ) )
      {
        logger.log( '? unprocessed src',n );
      }
      else
      {
        logger.log( '? unprocessed unknown',n );
      }

    }

    if( self.verbosity >= 2 )
    logger.log( unprocessedMapKeys.length + ' unprocessed files' );

  }

}

// --
// dependency
// --

function dependencyAdd( head,tails )
{
  var self = this;

  if( tails instanceof _.FileRecord )
  tails = [ tails ];

  _.assert( arguments.length === 2 );
  _.assert( head instanceof _.FileRecord );
  _.assert( _.arrayIs( tails ) );

  if( _.strHas( head.absolute,'backgroundDraw.chunk' ) )
  debugger;

  /* */

  var headToTails = self._headToTailsFor( head );
  for( var t = 0 ; t < tails.length ; t++ )
  {
    var tailRecord = tails[ t ];
    _.assert( tailRecord instanceof _.FileRecord );

    var tailNode = self.nodesMap[ headToTails.tails[ tailRecord.absolute ] ];
    if( tailNode )
    _.assert( self._nodeRecordSame( tailNode, tailRecord ) );
    headToTails.tails[ tailRecord.absolute ] = self._nodeForChanging( tailRecord );
    headToTails.tails[ tailRecord.absolute ] = headToTails.tails[ tailRecord.absolute ].absolute;
  }

  /* */

  for( var t = 0 ; t < tails.length ; t++ )
  {
    var tailRecord = tails[ t ];
    _.assert( tailRecord instanceof _.FileRecord );

    var tailToHeads = self._tailToHeadsFor( tailRecord );

    var headNode = self.nodesMap[ tailToHeads.heads[ head.absolute ] ];
    if( headNode )
    _.assert( self._nodeRecordSame( headNode, head ) );

    tailToHeads.heads[ head.absolute ] = self._nodeForChanging( head );
    tailToHeads.heads[ head.absolute ] = tailToHeads.heads[ head.absolute ].absolute;
  }

  /* */

  return self;
}

//

function _headToTailsFor( headRecord )
{
  var self = this;

  _.assert( arguments.length === 1 );
  _.assert( headRecord instanceof _.FileRecord );

  var dependency = self.tailsForHeadMap[ headRecord.absolute ];

  if( !dependency )
  {
    dependency = self.tailsForHeadMap[ headRecord.absolute ] = Object.create( null );
    dependency.tails = Object.create( null );
    dependency.head = self._nodeForChanging( headRecord );
    dependency.head = dependency.head.absolute;
    Object.preventExtensions( dependency );
  }
  else
  {
    self._nodeForChanging( headRecord );
  }

  return dependency;
}

//

function _tailToHeadsFor( tailRecord )
{
  var self = this;

  _.assert( arguments.length === 1 );
  _.assert( tailRecord instanceof _.FileRecord );

  var dependency = self.headsForTailMap[ tailRecord.absolute ];

  if( !dependency )
  {
    dependency = self.headsForTailMap[ tailRecord.absolute ] = Object.create( null );
    dependency.heads = Object.create( null );
    dependency.tail = self._nodeForChanging( tailRecord );
    dependency.tail = dependency.tail.absolute;
    Object.preventExtensions( dependency );
  }
  else
  {
    self._nodeForChanging( tailRecord );
  }

  return dependency;
}

// --
// node
// --

function _nodeMake( record )
{
  var self = this;

  _.assert( arguments.length === 1 );
  _.assert( !self.nodesMap[ record.absolute ] );

  var node = Object.create( null );
  self._nodeFromRecord( node,record );
  Object.preventExtensions( node );
  self.nodesMap[ record.absolute ] = node;

  return node;
}

//

function _nodeFor( record )
{
  var self = this;

  _.assert( arguments.length === 1 );

  var node = self.nodesMap[ record.absolute ];

  if( node )
  {
    _.assert( self._nodeRecordSame( node,record ) );
    return node;
  }

  node = self._nodeMake( record );

  return node;
}

//

function _nodeForChanging( record )
{
  var self = this;

  _.assert( arguments.length === 1 );

  var node = self.nodesMap[ record.absolute ];

  if( !node )
  {

    node = self._nodeMake( record );
    self.fileChange( record.absolute );

  }
  else
  {
    if( !self._nodeRecordSame( node,record ) )
    {
      self._nodeFromRecord( node,record );
      self.fileChange( record.absolute );
    }
  }

  return node;
}

//

function _nodeFromRecord( node,record )
{
  var self = this;
  var provider = self.provider;

  _.assert( arguments.length === 2 );
  _.assert( record instanceof _.FileRecord );

  node.absolute = record.absolute;
  node.relative = record.relative;

  if( !record.stat )
  {
    node.hash = null;
    node.hash2 = null;
    node.size = null;
    node.mtime = null;
    node.ctime = null;
    node.birthtime = null;
  }
  else
  {
    node.hash = record.hashGet();
    node.hash2 = _.fileStatHashGet( record.stat );
    node.size = record.stat.size;
    node.mtime = record.stat.mtime.getTime();
    node.ctime = record.stat.ctime.getTime();
    node.birthtime = record.stat.birthtime.getTime();
  }

  return node;
}

//

function _nodeRecordSame( node,record )
{
  var self = this;
  var provider = self.provider;

  _.assert( arguments.length === 2 );
  _.assert( _.mapIs( node ) );
  _.assert( record instanceof _.FileRecord );

  if( !record.stat )
  return false;

  if( node.absolute !== record.absolute )
  return false;

  if( node.relative !== record.relative )
  return false;

  if( node.size !== record.stat.size )
  return false;

  if( node.mtime !== record.stat.mtime.getTime() )
  return false;

  if( node.ctime !== record.stat.ctime.getTime() )
  return false;

  if( node.birthtime !== record.stat.birthtime.getTime() )
  return false;

  // if( node.hash !== record.hashGet() )
  // return false;

  return true;
}

// --
// etc
// --

function _hashFor( src )
{

  var result;
  var crypto = require( 'crypto' );
  var md5sum = crypto.createHash( 'md5' );

  _.assert( arguments.length === 1 );

  try
  {
    md5sum.update( src );
    result = md5sum.digest( 'hex' );
  }
  catch( err )
  {
    throw _.err( err );
  }

  return result;
}

//

function storageLoadEnd( storageFilePath,mapExtend )
{
  var self = this;
  var fileProvider = self.fileProvider;

  _.assert( arguments.length === 2 );

  _.mapExtend( self.unprocessedMap,mapExtend.nodesMap );

  var storage = _.mapExtend( self.storageToStore,mapExtend );
  self.storageToStore = storage;

  return true;
}

// --
// actionName
// --

function actionReset()
{
  var self = this;
  self.basePath = null;
}

//

function actionFuture( actionName )
{
  var self = this;

  _.assert( _.strIs( actionName ) || actionName === null );

  self.futureAction = actionName;

}

//

function actionBegin( actionName )
{
  var self = this;

  _.assert( self.currentAction === null );
  _.assert( _.strIs( actionName ) || actionName === null );
  _.assert( arguments.length === 1 );

  /* name */

  if( self.futureAction )
  {
    actionName = self.futureAction + actionName;
    self.futureAction = null
  }

  self.currentAction = actionName;

  /* path */

  self.srcPath = _.pathNormalize( self.srcPath );
  self.dstPath = _.pathNormalize( self.dstPath );
  if( self.basePath === null )
  self.basePath = _.pathCommon([ self.srcPath, self.dstPath ]);

  /* storage */

  self.storageLoad( self.dstPath );

}

//

function actionEnd( actionName )
{
  var self = this;

  _.assert( self.currentAction === actionName || actionName === undefined );
  _.assert( arguments.length === 0 || arguments.length === 1 );

  self.unprocessedReport();
  self.unprocessedDelete();

  self.storageSave( self.dstPath );

  self.currentAction = null;
}

// --
//
// --

function _verbositySet( val )
{
  var self = this;

  _.assert( arguments.length === 1 );

  if( !_.numberIs( val ) )
  val = val ? 1 : 0;
  if( val < 0 )
  val = 0;

  self[ verbositySymbol ] = val;
}

//

function _storageToStoreSet( storage )
{
  var self = this;

  _.assert( arguments.length === 1 );

  // self.changedMap = storage.changedMap;
  self.nodesMap = storage.nodesMap;
  self.headsForTailMap = storage.headsForTailMap;
  self.tailsForHeadMap = storage.tailsForHeadMap;

}

//

function _storageToStoreGet()
{
  var self = this;
  var storage = Object.create( null );

  // storage.changedMap = self.changedMap;
  storage.nodesMap = self.nodesMap;
  storage.headsForTailMap = self.headsForTailMap;
  storage.tailsForHeadMap = self.tailsForHeadMap;

  return storage;
}

// --
//
// --

var verbositySymbol = Symbol.for( 'verbosity' );

var Composes =
{

  verbosity : 5,

  currentAction : null,
  futureAction : null,

  storageFileName : '.wfilesgraph',
  basePath : null,
  dstPath : '/',
  srcPath : '/',
  unporcessedDstUnmapping : 1,
  unporcessedDstDeleting : 1,

  changedMap : Object.create( null ),
  unprocessedMap : Object.create( null ),

  nodesMap : Object.create( null ),
  headsForTailMap : Object.create( null ),
  tailsForHeadMap : Object.create( null ),

}

var Aggregates =
{
}

var Associates =
{
  fileProvider : null,
}

var Restricts =
{
}

var Statics =
{
}

var Forbids =
{

  comparingRelyOnHardLinks : 'comparingRelyOnHardLinks',
  replacingByNewest : 'replacingByNewest',
  maxSize : 'maxSize',

  fileByHashMap : 'fileByHashMap',

  fileMap : 'fileMap',
  fileAddedMap : 'fileAddedMap',
  fileRemovedMap : 'fileRemovedMap',
  fileModifiedMap : 'fileModifiedMap',

  fileHashMap : 'fileHashMap',

  fileMapAutosaving : 'fileMapAutosaving',
  fileMapAutoLoading : 'fileMapAutoLoading',

  mask : 'mask',
  dependencyMap : 'dependencyMap',

}

var Accessors =
{
  verbosity : 'verbosity',
  storageToStore : 'storageToStore',
}

// --
// prototype
// --

var Proto =
{

  init : init,

  // contentUpdate : contentUpdate,
  // statUpdate : statUpdate,

  // iterator

  _eachHeadPre : _eachHeadPre,
  _eachHeadBody : _eachHeadBody,
  eachHead : eachHead,


  // file

  fileChange : fileChange,
  filesUpdate : filesUpdate,
  fileDeletedUpdate : fileDeletedUpdate,
  fileIsUpToDate : fileIsUpToDate,

  unprocessedDelete : unprocessedDelete,
  unprocessedReport : unprocessedReport,


  // dependency

  dependencyAdd : dependencyAdd,
  _headToTailsFor : _headToTailsFor,
  _tailToHeadsFor : _tailToHeadsFor,


  // node

  _nodeMake : _nodeMake,
  _nodeFor : _nodeFor,
  _nodeForChanging : _nodeForChanging,

  _nodeFromRecord : _nodeFromRecord,
  _nodeRecordSame : _nodeRecordSame,

  // etc

  _hashFor : _hashFor,
  storageLoadEnd : storageLoadEnd,


  // action

  actionReset : actionReset,
  actionFuture : actionFuture,
  actionBegin : actionBegin,
  actionEnd : actionEnd,


  //

  _verbositySet : _verbositySet,
  _storageToStoreSet : _storageToStoreSet,
  _storageToStoreGet : _storageToStoreGet,


  //

  constructor : Self,
  Composes : Composes,
  Aggregates : Aggregates,
  Associates : Associates,
  Restricts : Restricts,
  Statics : Statics,
  Forbids : Forbids,
  Accessors : Accessors,

}

//

_.classMake
({
  cls : Self,
  parent : Parent,
  extend : Proto,
});

//

_.Copyable.mixin( Self );
_.FileStorage.mixin( Self );
_global_[ Self.name ] = _[ Self.nameShort ] = Self;

// --
// export
// --

if( typeof module !== 'undefined' )
if( _global_._UsingWtoolsPrivately_ )
delete require.cache[ module.id ];

if( typeof module !== 'undefined' && module !== null )
module[ 'exports' ] = Self;

})();
