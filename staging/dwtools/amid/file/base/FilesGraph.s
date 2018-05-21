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

//

function fileChange( path )
{
  var self = this;

  _.assert( arguments.length === 1 );

  self.changedMap[ path ] = true;

  /* xxx */

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

  return self;
}

//

function dependencyIsUpToDate( head,tails )
{
  var self = this;

  if( tails instanceof _.FileRecord )
  tails = [ tails ];

  _.assert( arguments.length === 2 );
  _.assert( head instanceof _.FileRecord );
  _.assert( _.arrayIs( tails ) );

  var change = false;

  debugger;

  self.filesUpdate( head );
  self.filesUpdate( tails );

  if( self.changedMap[ head.absolute ] )
  return false;

  debugger;

  // var dependency = self._dependencyGet( head );
  //
  // // var dependency = self._dependencyGet( head );
  //
  // if( !dependency )
  // return false;
  //
  // debugger;
  //
  // if( !self._nodeRecordSame( dependency.head, head ) )
  // {
  //   debugger;
  //   return false;
  // }
  //
  // debugger; xxx

  return true;
}

//

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
    headToTails.tails[ tailRecord.absolute ] = self._nodeFor( tailRecord );
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

    tailToHeads.heads[ head.absolute ] = self._nodeFor( head );
    tailToHeads.heads[ head.absolute ] = tailToHeads.heads[ head.absolute ].absolute;
  }

  /* */

  return self;
}

//
//
// function _dependencyGet( headRecord )
// {
//   var self = this;
//
//   _.assert( arguments.length === 1 );
//   _.assert( headRecord instanceof _.FileRecord );
//
//   var dependency = self.tailsForHeadMap[ headRecord.absolute ];
//
//   return dependency;
// }
//
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
    dependency.head = self._nodeFor( headRecord );
    dependency.head = dependency.head.absolute;
    Object.preventExtensions( dependency );
  }
  else
  {
    // debugger;
    self._nodeFor( headRecord );
    // var same = self._nodeRecordSame( dependency.head, headRecord );
    // if( !same )
    // {
    //   self._nodeFromRecord( dependency.head, headRecord );
    // }
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
    dependency.tail = self._nodeFor( tailRecord );
    dependency.tail = dependency.tail.absolute;
    Object.preventExtensions( dependency );
  }
  else
  {
    // debugger;
    self._nodeFor( tailRecord );
    // var same = self._nodeRecordSame( dependency.head, tailRecord );
    // if( !same )
    // {
    //   self._nodeFromRecord( dependency.head, tailRecord );
    // }
  }

  return dependency;
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

function _nodeFromRecord( node,record )
{
  var self = this;
  var provider = self.provider;

  _.assert( arguments.length === 2 );
  _.assert( record instanceof _.FileRecord );
  _.assert( record.stat );

  node.absolute = record.absolute;
  node.relative = record.relative;
  node.hash = record.hashGet();
  node.hash2 = _.fileStatHashGet( record.stat );
  node.size = record.stat.size;
  node.mtime = record.stat.mtime.getTime();
  node.ctime = record.stat.ctime.getTime();
  node.birthtime = record.stat.birthtime.getTime();

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
  _.assert( record.stat );

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

//

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

function actionBegin( action )
{
  var self = this;

  _.assert( _.strIs( action ) || action === null );

  self.currentAction = action;



}

//

function actionEnd( action )
{
  var self = this;

  _.assert( self.currentAction === action );

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

  verbosity : 3,
  storageFileName : '.wfilesgraph',
  basePath : '/',
  currentAction : null,

  // dependencyMap : Object.create( null ),

  changedMap : Object.create( null ),
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

  // basePath : 'basePath',

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

  fileChange : fileChange,
  filesUpdate : filesUpdate,

  dependencyIsUpToDate : dependencyIsUpToDate,
  dependencyAdd : dependencyAdd,
  // _dependencyGet : _dependencyGet,

  _headToTailsFor : _headToTailsFor,
  _tailToHeadsFor : _tailToHeadsFor,

  _nodeMake : _nodeMake,
  _nodeFor : _nodeFor,
  _nodeForChanging : _nodeForChanging,

  _nodeFromRecord : _nodeFromRecord,
  _nodeRecordSame : _nodeRecordSame,

  _hashFor : _hashFor,

  actionBegin : actionBegin,
  actionEnd : actionEnd,


  //

  _verbositySet : _verbositySet,
  _storageToStoreSet : _storageToStoreSet,
  _storageToStoreGet : _storageToStoreGet,

  // _storageToStoreSet : _.setterAlias_functor({ original : 'dependencyMap', alias : 'storageToStore' }),
  // _storageToStoreGet : _.getterAlias_functor({ original : 'dependencyMap', alias : 'storageToStore' }),


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
