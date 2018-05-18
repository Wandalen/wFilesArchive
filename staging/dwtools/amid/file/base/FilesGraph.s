( function _FilesGraph_s_() {

'use strict';

if( typeof module !== 'undefined' )
{

  require( '../FileBase.s' );

}

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
  var archive = this;

  _.assert( arguments.length === 0 || arguments.length === 1 );

  _.instanceInit( archive );
  Object.preventExtensions( archive )

  if( o )
  archive.copy( o );

}

//

function contentUpdate( head,data )
{
  var archive = this;

  _.assert( arguments.length === 2 );

  var head = _.FileRecord.from( head );
  var dependency = archive._dependencyFor( head );

  dependency.info.hash = archive._hashFor( data );

  return dependency;
}

//

function statUpdate( head,stat )
{
  var archive = this;

  _.assert( arguments.length === 2 );

  var head = _.FileRecord.from( head );
  var dependency = archive._dependencyFor( head );

  dependency.info.mtime = stat.mtime;
  dependency.info.ctime = stat.ctime;
  dependency.info.birthtime = stat.birthtime;
  dependency.info.size = stat.size;

  return dependency;
}

//

function dependencyAdd( head,tails )
{
  var archive = this;

  _.assert( arguments.length === 2 );

  // head = _.FileRecord.from( head );
  // tails = _.FileRecord.manyFrom( tails );

  if( tails instanceof _.FileRecord )
  tails = [ tails ];

  _.assert( head instanceof _.FileRecord );
  _.assert( _.arrayIs( tails ) );

  var dependency = archive._dependencyFor( head );

  for( var t = 0 ; t < tails.length ; t++ )
  {
    var tail = tails[ t ];
    _.assert( tail instanceof _.FileRecord );
    if( dependency.tails[ tail.absolute ] )
    _.assert( archive._infoRecordSame( dependency.tails[ tail.absolute ], tail ) );
    dependency.tails[ tail.absolute ] = archive._infoFor( tail );
  }

  return dependency;
}

//

function _dependencyFor( head )
{
  var archive = this;

  _.assert( arguments.length === 1 );
  _.assert( head instanceof _.FileRecord );

  var dependency = archive.dependencyMap[ head.absolute ];

  if( !dependency )
  {
    dependency = archive.dependencyMap[ head.relative ] = Object.create( null );
    dependency.head = head.relative;
    dependency.tails = Object.create( null );
    dependency.head = archive._infoFor( head );
    Object.preventExtensions( dependency );
  }
  else
  {
    _.assert( archive._infoRecordSame( dependency.head, head ) );
  }

  return dependency;
}

//

function _infoFor( record )
{
  var archive = this;
  var provider = archive.provider;

  _.assert( arguments.length === 1 );
  _.assert( record instanceof _.FileRecord );
  _.assert( record.stat );

  var info = Object.create( null );
  info.absolute = record.absolute;
  info.relative = record.relative;
  info.hash = record.hashGet();
  info.hash2 = _.statsHash2Get( record.stat );
  info.size = record.stat.size;
  info.mtime = record.stat.mtime;
  info.ctime = record.stat.ctime;
  info.birthtime = record.stat.birthtime;
  Object.preventExtensions( info );

  return info;
}

//

function _infoRecordSame( info,record )
{
  var archive = this;
  var provider = archive.provider;

  _.assert( arguments.length === 2 );
  _.assert( _.mapIs( info ) );
  _.assert( record instanceof _.FileRecord );
  _.assert( record.stat );

  if( info.absolute !== record.absolute )
  return false;

  if( info.relative !== record.relative )
  return false;

  if( info.size !== record.stat.size )
  return false;

  if( info.mtime !== record.stat.mtime )
  return false;

  if( info.ctime !== record.stat.ctime )
  return false;

  if( info.birthtime !== record.stat.birthtime )
  return false;

  // if( info.hash !== record.hashGet() )
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
  var archive = this;

  _.assert( arguments.length === 1 );

  if( !_.numberIs( val ) )
  val = val ? 1 : 0;
  if( val < 0 )
  val = 0;

  archive[ verbositySymbol ] = val;
}

// --
//
// --

var verbositySymbol = Symbol.for( 'verbosity' );

var Composes =
{
  verbosity : 2,
  storageFileName : '.wfilesgraph',
  dependencyMap : Object.create( null ),
  currentAction : null,
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

  trackPath : 'trackPath',

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
}

// --
// prototype
// --

var Proto =
{

  init : init,

  contentUpdate : contentUpdate,
  statUpdate : statUpdate,

  dependencyAdd : dependencyAdd,
  _dependencyFor : _dependencyFor,

  _infoFor : _infoFor,
  _infoRecordSame : _infoRecordSame,

  _hashFor : _hashFor,

  actionBegin : actionBegin,
  actionEnd : actionEnd,


  //

  _verbositySet : _verbositySet,


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
