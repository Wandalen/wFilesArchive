( function _aFileStorageMixin_s_() {

'use strict';

//

var _global = _global_; var _ = _global_.wTools;
var Parent = null;
var Self = function wFileStorage( o )
{
  if( !( this instanceof Self ) )
  if( o instanceof Self )
  {
    _.assert( arguments.length === 1, 'expects single argument' );
    return o;
  }
  else
  return new( _.routineJoin( Self, Self, arguments ) );
  return Self.prototype.init.apply( this,arguments );
}

Self.nameShort = 'FileStorage';

//

function _storageSave( o )
{
  var self = this;
  var fileProvider = self.fileProvider;

  _.assert( arguments.length === 1, 'expects single argument' );
  _.routineOptions( _storageSave,arguments );

  if( self.verbosity >= 3 )
  logger.log( '+ saving ' + _.strReplaceAll( self.storageFileName,'.','' ) + ' ' + o.storageFilePath );

  var map = self.storageToStore;
  if( o.splitting )
  {
    var storageDirPath = _.pathDir( o.storageFilePath );
    map = Object.create( null );
    for( var m in self.storageToStore )
    {
      if( _.strBegins( m,storageDirPath ) )
      map[ m ] = self.storageToStore[ m ];
    }
  }

  fileProvider.fileWriteJson
  ({
    filePath : o.storageFilePath,
    data : map,
    pretty : 1,
    sync : 1,
  });

}

_storageSave.defaults =
{
  storageFilePath : null,
  splitting : 0,
}

//

function storageSave( basePath )
{
  var self = this;
  var fileProvider = self.fileProvider;
  var basePath = basePath ? _.pathsGet( basePath ) : self.basePath;
  var storageFilePath = _.pathsJoin( basePath , self.storageFileName );

  _.assert( arguments.length === 0 || arguments.length === 1 );

  if( _.arrayIs( storageFilePath ) )
  for( var p = 0 ; p < storageFilePath.length ; p++ )
  self._storageSave
  ({
    storageFilePath : storageFilePath[ p ],
    splitting : 1,
  })
  else
  self._storageSave
  ({
    storageFilePath : storageFilePath,
    splitting : 0,
  });

}

//

function storageLoad( storageDirPath )
{
  var self = this;
  var fileProvider = self.fileProvider;
  var storageDirPath = _.pathGet( storageDirPath );
  var storageFilePath = _.pathJoin( storageDirPath , self.storageFileName );

  _.assert( arguments.length === 1, 'expects single argument' );

  if( !fileProvider.fileStat( storageFilePath ) )
  return false;

  for( var f = 0 ; f < self.loadedStorages.length ; f++ )
  {
    var loadedStorage = self.loadedStorages[ f ];
    if( _.strBegins( storageDirPath,loadedStorage.dirPath ) && ( storageFilePath !== loadedStorage.filePath ) )
    return false;
  }

  if( self.verbosity >= 3 )
  logger.log( '. loading ' + _.strReplaceAll( self.storageFileName,'.','' ) + ' ' + storageFilePath );
  var mapExtend = fileProvider.fileReadJson( storageFilePath );

  var extended = self.storageLoadEnd( storageFilePath,mapExtend );

  if( extended )
  self.loadedStorages.push({ dirPath : storageDirPath, filePath : storageFilePath });

  return extended;
}

//

function storageLoadEnd( storageFilePath,mapExtend )
{
  var self = this;
  var fileProvider = self.fileProvider;

  _.assert( arguments.length === 2, 'expects exactly two argument' );

  var storage = _.mapExtend( self.storageToStore,mapExtend );
  self.storageToStore = storage;

  return true;
}

// --
//
// --

var Composes =
{
  storageFileName : '.storage',
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
  loadedStorages : [],
}

var Statics =
{
}

var Forbids =
{
}

var Accessors =
{
}

// --
// define class
// --

var Supplement =
{

  _storageSave : _storageSave,
  storageSave : storageSave,
  storageLoad : storageLoad,
  storageLoadEnd : storageLoadEnd,


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

var _Self = _.classMake
({
  cls : Self,
  parent : Parent,
  supplement : Supplement,
  withMixin : true,
  withClass : true,
});

//

_global_[ Self.name ] = _[ Self.nameShort ] = Self;

// --
// export
// --

if( typeof module !== 'undefined' )
if( _global_.WTOOLS_PRIVATE )
delete require.cache[ module.id ];

if( typeof module !== 'undefined' && module !== null )
module[ 'exports' ] = Self;

})();
