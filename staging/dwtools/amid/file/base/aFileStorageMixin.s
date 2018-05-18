( function _aFileStorageMixin_s_() {

'use strict';

//

var _ = _global_.wTools;
var Parent = null;
var Self = function wFileStorage( o )
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

Self.nameShort = 'FileStorage';

//

function _storageSave( o )
{
  var self = this;
  var fileProvider = self.fileProvider;

  _.assert( arguments.length === 1 );

  if( self.verbosity >= 3 )
  logger.log( '+ saving ' + _.strReplaceAll( self.storageFileName,'.','' ) + ' ' + o.archiveFilePath );

  var map = self.fileMap;
  if( o.splitting )
  {
    var archiveDirPath = _.pathDir( o.archiveFilePath );
    map = Object.create( null );
    for( var m in self.fileMap )
    {
      if( _.strBegins( m,archiveDirPath ) )
      map[ m ] = self.fileMap[ m ];
    }
  }

  fileProvider.fileWriteJson
  ({
    filePath : o.archiveFilePath,
    data : map,
    pretty : 1,
    sync : 1,
  });

}

_storageSave.defaults =
{
  archiveFilePath : null,
  splitting : 0,
}

//

function storageSave()
{
  var self = this;
  var fileProvider = self.fileProvider;
  var archiveFilePath = _.pathsJoin( self.trackPath , self.storageFileName );

  _.assert( arguments.length === 0 );

  if( _.arrayIs( archiveFilePath ) )
  for( var p = 0 ; p < archiveFilePath.length ; p++ )
  self._storageSave
  ({
    archiveFilePath : archiveFilePath[ p ],
    splitting : 1,
  })
  else
  self._storageSave
  ({
    archiveFilePath : archiveFilePath,
    splitting : 0,
  });

}

//

function storageLoad( archiveDirPath )
{
  var self = this;
  var fileProvider = self.fileProvider;
  var archiveFilePath = _.pathJoin( archiveDirPath , self.storageFileName );

  debugger;

  _.assert( arguments.length === 1 );

  if( !fileProvider.fileStat( archiveFilePath ) )
  return false;

  for( var f = 0 ; f < self.loadedStorages.length ; f++ )
  {
    var loadedArchive = self.loadedStorages[ f ];
    if( _.strBegins( archiveDirPath,loadedArchive.dirPath ) && ( archiveFilePath !== loadedArchive.filePath ) )
    return false;
  }

  if( self.verbosity >= 3 )
  logger.log( '. loading ' + _.strReplaceAll( self.storageFileName,'.','' ) + ' ' + archiveFilePath );
  var mapExtend = fileProvider.fileReadJson( archiveFilePath );
  _.mapExtend( self.fileMap,mapExtend );

  self.loadedStorages.push({ dirPath : archiveDirPath, filePath : archiveFilePath });

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
// prototype
// --

var Supplement =
{

  _storageSave : _storageSave,
  storageSave : storageSave,
  storageLoad : storageLoad,


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
if( _global_._UsingWtoolsPrivately_ )
delete require.cache[ module.id ];

if( typeof module !== 'undefined' && module !== null )
module[ 'exports' ] = Self;

})();
