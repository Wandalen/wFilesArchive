( function _FilesArchive_s_() {

'use strict';

/**
  @module Tools/mid/FilesArchive - Experimental. Several classes to reflect changes of files on dependent files and keep links of hard linked files. FilesArchive provides means to define interdependence between files and to forward changes from dependencies to dependents. Use FilesArchive to avoid unnecessary CPU workload.
*/

/**
 * @file files/FilesArchive.s.
 */

//

let _global = _global_;
let _ = _global_.wTools;
let Parent = null;
let Self = function wFilesArchive( o )
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

Self.shortName = 'FilesArchive';

//

function init( o )
{
  let archive = this;

  _.assert( arguments.length === 0 || arguments.length === 1 );

  _.instanceInit( archive );
  Object.preventExtensions( archive )

  if( o )
  archive.copy( o );

}

//

function filesUpdate()
{
  let archive = this;
  let fileProvider = archive.fileProvider;
  let time = _.timeNow();

  let fileMapOld = archive.fileMap;
  archive.fileAddedMap = Object.create( null );
  archive.fileRemovedMap = null;
  archive.fileModifiedMap = Object.create( null );
  archive.fileHashMap = null;

  _.assert( _.strIsNotEmpty( archive.basePath ) || _.strsAreNotEmpty( archive.basePath ) );

  let filePath = _.strJoin( archive.basePath, '/**' );
  if( archive.verbosity >= 3 )
  logger.log( ' : filesUpdate', filePath );

  /* */

  let fileMapNew = Object.create( null );

  /* */

  archive.mask = _.RegexpObject( archive.mask );

  debugger;
  let files = fileProvider.filesFind
  ({
    filePath : filePath,
    filter :
    {
      maskAll : archive.mask,
      maskTransientAll : archive.mask,
    },
    onUp : onFile,
    includingTerminals : 1,
    includingDirectories : 1,
    includingTransients : 0,
    recursive : 1,
  });

  archive.fileRemovedMap = fileMapOld;
  archive.fileMap = fileMapNew;

  debugger;
  if( archive.fileMapAutosaving )
  archive.storageSave();

  if( archive.verbosity >= 8 )
  {
    logger.log( 'fileAddedMap',archive.fileAddedMap );
    logger.log( 'fileRemovedMap',archive.fileRemovedMap );
    logger.log( 'fileModifiedMap',archive.fileModifiedMap );
  }
  else if( archive.verbosity >= 6 )
  {
    logger.log( 'fileAddedMap', _.entityLength( archive.fileAddedMap ) );
    logger.log( 'fileRemovedMap', _.entityLength( archive.fileRemovedMap ) );
    logger.log( 'fileModifiedMap', _.entityLength( archive.fileModifiedMap ) );
  }

  if( archive.verbosity >= 4 )
  {
    logger.log( ' . filesUpdate', filePath, 'found', _.entityLength( fileMapNew ),'file(s)', _.timeSpent( 'in ',time ) );
  }

  return archive;

  /* */

  function onFile( record,op )
  {
    let d = null;
    let isDir = record.stat.isDirectory();

    if( isDir )
    if( archive.fileMapAutoLoading )
    {
      debugger;
      let loaded = archive._storageFilesRead( record.absolute );
      if( !loaded && record.isBranch )
      archive.storageLoaded({ storageFilePath : archive.storageFileFromDirPath( record.absolute ), storage : storage });
    }

    if( archive.verbosity >= 7 )
    logger.log( ' . investigating ' + record.absolute );

    if( fileMapOld[ record.absolute ] )
    {
      d = _.mapExtend( null,fileMapOld[ record.absolute ] );
      delete fileMapOld[ record.absolute ];
      let same = true;
      same = same && d.mtime === record.stat.mtime.getTime();
      same = same && d.birthtime === record.stat.birthtime.getTime();
      same = same && ( isDir || d.size === record.stat.size );
      if( same && archive.comparingRelyOnHardLinks && !isDir )
      {
        if( d.nlink === 1 )
        debugger;
        same = d.nlink === record.stat.nlink;
      }

      if( same )
      {
        fileMapNew[ d.absolutePath ] = d;
        return d;
      }
      else
      {
        if( archive.verbosity >= 5 )
        logger.log( ' . change ' + record.absolute );
        archive.fileModifiedMap[ record.absolute ] = d;
        d = _.mapExtend( null,d );
      }
    }
    else
    {
      d = Object.create( null );
      archive.fileAddedMap[ record.absolute ] = d;
    }

    d.mtime = record.stat.mtime.getTime();
    d.ctime = record.stat.ctime.getTime();
    d.birthtime = record.stat.birthtime.getTime();
    d.absolutePath = record.absolute;
    if( !isDir )
    {
      d.size = record.stat.size;
      if( archive.maxSize === null || record.stat.size <= archive.maxSize )
      d.hash = fileProvider.fileHash({ filePath : record.absolute, throwing : 0, sync : 1 });
      d.hash2 = _.fileStatHashGet( record.stat );
      d.nlink = record.stat.nlink;
    }

    fileMapNew[ d.absolutePath ] = d;
    return d;
  }

}

//

function filesHashMapForm()
{
  let archive = this;

  _.assert( !archive.fileHashMap );

  archive.fileHashMap = Object.create( null );

  for( let f in archive.fileMap )
  {
    let file = archive.fileMap[ f ];
    if( file.hash )
    if( archive.fileHashMap[ file.hash ] )
    archive.fileHashMap[ file.hash ].push( file.absolutePath );
    else
    archive.fileHashMap[ file.hash ] = [ file.absolutePath ];
  }

  // debugger;
  // for( let h in archive.fileHashMap )
  // logger.log( archive.fileHashMap[ h ].length, _.toStr( archive.fileHashMap[ h ],{ levels : 3, wrap : 0 } ) );

  return archive.fileHashMap;
}

//

function filesLinkSame( o )
{
  let archive = this;
  let provider = archive.fileProvider;
  let fileHashMap = archive.filesHashMapForm();
  o = _.routineOptions( filesLinkSame,arguments );

  debugger;
  for( let f in fileHashMap )
  {
    let files = fileHashMap[ f ];

    if( files.length < 2 )
    continue;

    if( o.consideringFileName )
    {
      let byName = {};
      debugger;
      _.entityFilter( files,function( path )
      {
        let name = _.path.fullName( path );
        if( byName[ name ] )
        byName[ name ].push( path );
        else
        byName[ name ] = [ path ];
      });
      for( let name in byName )
      provider.linkHard({ dstPath : byName[ name ], verbosity : archive.verbosity });
    }
    else
    {
      // console.log( 'archive.verbosity',archive.verbosity );
      provider.linkHard({ dstPath : files, verbosity : archive.verbosity });
    }

  }

  return archive;
}

filesLinkSame.defaults =
{
  consideringFileName : 0,
}

//

function restoreLinksBegin()
{
  let archive = this;
  let provider = archive.fileProvider;

  archive.filesUpdate();

}

//

function restoreLinksEnd()
{
  let archive = this;
  let provider = archive.fileProvider;
  let fileMap1 = _.mapExtend( null, archive.fileMap );
  let fileHashMap = archive.filesHashMapForm();
  let restored = 0;

  archive.filesUpdate();

  _.assert( archive.fileMap,'restoreLinksBegin should be called before calling restoreLinksEnd' );

  let fileMap2 = _.mapExtend( null,archive.fileMap );
  let fileModifiedMap = archive.fileModifiedMap;
  let linkedMap = Object.create( null );

  /* */

  for( let f in fileModifiedMap )
  {
    let modified = fileModifiedMap[ f ];
    let filesWithHash = fileHashMap[ modified.hash ];

    if( linkedMap[ f ] )
    continue;

    if( modified.hash === undefined )
    continue;

    /* remove removed files and use old file descriptors */

    filesWithHash = _.entityFilter( filesWithHash,( e ) => fileMap2[ e ] ? fileMap2[ e ] : undefined );

    /* find newest file */

    if( archive.replacingByNewest )
    filesWithHash.sort( ( e1,e2 ) => e2.mtime-e1.mtime );
    else
    filesWithHash.sort( ( e1,e2 ) => e1.mtime-e2.mtime );

    let newest = filesWithHash[ 0 ];
    let mostLinked = _.entityMax( filesWithHash,( e ) => e.nlink ).element;

    if( mostLinked.absolutePath !== newest.absolutePath )
    {
      let read = provider.fileRead({ filePath : newest.absolutePath, encoding : 'original.type' });
      provider.fileWrite( mostLinked.absolutePath,read );
    }

    /* use old file descriptors */

    filesWithHash = _.entityFilter( filesWithHash,( e ) => fileMap1[ e.absolutePath ] );
    mostLinked = fileMap1[ mostLinked.absolutePath ];

    /* verbosity */

    if( archive.verbosity >= 4 )
    logger.log( 'modified',_.toStr( _.entitySelect( filesWithHash,'*.absolutePath' ),{ levels : 2 } ) );

    /*  */

    let srcPath = mostLinked.absolutePath;
    let srcFile = mostLinked;
    linkedMap[ srcPath ] = srcFile;
    for( let last = 0 ; last < filesWithHash.length ; last++ )
    {
      let dstPath = filesWithHash[ last ].absolutePath;
      if( srcFile.absolutePath === dstPath )
      continue;
      if( linkedMap[ dstPath ] )
      continue;
      let dstFile = filesWithHash[ last ];
      /* if this files where linked before changes, relink them */
      if( srcFile.hash2 === dstFile.hash2 )
      {
        debugger;
        restored += 1;
        provider.linkHard({ dstPath : dstPath, srcPath : srcPath, verbosity : archive.verbosity });
        linkedMap[ dstPath ] = filesWithHash[ last ];
      }
    }

  }

  if( archive.verbosity >= 1 )
  logger.log( '+ Restored',restored,'links' );
}

//

function _loggerGet()
{
  let self = this;
  let fileProvider = self.fileProvider;
  if( fileProvider )
  return fileProvider.logger;
  return null;
}

// --
// storage
// --

// function storageDirPathGet( storageDirPath )
// {
//   let self = this;
//   let fileProvider = self.fileProvider;
//
//   _.assert( arguments.length === 0 || arguments.length === 1 );
//   _.assert( !!storageDirPath );
//   _.assert( _.all( storageDirPath, ( path ) => fileProvider.path.isAbsolute( path ) ) );
//
//   return storageDirPath;
// }

//

function storageFilePathToSaveGet( storageDirPath )
{
  let self = this;
  let fileProvider = self.fileProvider;
  let storageFilePath = null;

  _.assert( arguments.length === 0 || arguments.length === 1 );

  storageFilePath = _.entitySelect( self.storagesLoaded, '*.filePath' );

  _.sure
  (
    _.all( storageFilePath, ( storageFilePath ) => _.fileProvider.directoryIs( _.fileProvider.path.dir( storageFilePath ) ) ),
    () => 'Directory for storage file does not exist ' + _.strQuote( storageFilePath )
  );

  return storageFilePath;
}

//

function storageToSave( o )
{
  let self = this;

  o = _.routineOptions( storageToSave, arguments );

  let storage = self.fileMap;

  if( o.splitting )
  {
    let storageDirPath = _.path.dir( o.storageFilePath );
    let fileMap = self.fileMap;
    storage = Object.create( null );
    for( let m in fileMap )
    {
      if( _.strBegins( m, storageDirPath ) )
      storage[ m ] = fileMap[ m ];
    }
  }

  return storage;
}

storageToSave.defaults =
{
  storageFilePath : null,
  splitting : 1,
}

//

function storageLoaded( o )
{
  let self = this;
  let fileProvider = self.fileProvider;

  _.sure( self.storageIs( o.storage ), () => 'Strange storage : ' + _.toStrShort( o.storage ) );
  _.assert( arguments.length === 2, 'expects exactly two arguments' );
  _.assert( _.strIs( o.storageFilePath ) );

  if( self.storagesLoaded !== undefined )
  {
    _.assert( _.arrayIs( self.storagesLoaded ), () => 'expects {-self.storagesLoaded-}, but got ' + _.strTypeOf( self.storagesLoaded ) );
    self.storagesLoaded.push({ filePath : o.storageFilePath });
  }

  debugger;
  _.mapExtend( self.fileMap, o.storage );

  return true;
}

// --
// vars
// --

let verbositySymbol = Symbol.for( 'verbosity' );
let mask =
{
  excludeAny :
  [
    /(\W|^)node_modules(\W|$)/,
    /\.unique$/,
    /\.git$/,
    /\.svn$/,
    /\.hg$/,
    /\.tmp($|\/|\.)/,
    /\.big($|\/|\.)/,
    /(^|\/)\.(?!$|\/)/,
    /(^|\/)\-(?!$|\/)/,
  ],
};

// --
// relations
// --

let Composes =
{
  verbosity : 2,

  basePath : null,

  comparingRelyOnHardLinks : 0,
  replacingByNewest : 1,
  maxSize : null,

  fileByHashMap : _.define.own( {} ),

  fileMap : _.define.own( {} ),
  fileAddedMap : _.define.own( {} ),
  fileRemovedMap : _.define.own( {} ),
  fileModifiedMap : _.define.own( {} ),

  fileHashMap : null,

  fileMapAutosaving : 0,
  fileMapAutoLoading : 1,

  mask : _.define.own( mask ), /* !!! not shallow clone required */

  storageFileName : '.warchive',

  storageSaveAsJs : true

}

let Aggregates =
{
}

let Associates =
{
  fileProvider : null,
}

let Restricts =
{
  storagesLoaded : _.define.own([]),
}

let Statics =
{
}

let Forbids =
{
  dependencyMap : 'dependencyMap',
}

let Accessors =
{
  logger : { readOnly : 1 },
  // storage : 'storage',
}

// --
// declare
// --

let Proto =
{

  init : init,

  filesUpdate : filesUpdate,
  filesHashMapForm : filesHashMapForm,
  filesLinkSame : filesLinkSame,

  restoreLinksBegin : restoreLinksBegin,
  restoreLinksEnd : restoreLinksEnd,

  _loggerGet : _loggerGet,

  // storage

  // storageDirPathGet : storageDirPathGet,
  storageFilePathToSaveGet : storageFilePathToSaveGet,
  storageToSave : storageToSave,
  storageLoaded : storageLoaded,
  // _storageSet : _.setterAlias_functor({ original : 'fileMap', alias : 'storage' }),
  // _storageGet : _.getterAlias_functor({ original : 'fileMap', alias : 'storage' }),

  //

  Composes : Composes,
  Aggregates : Aggregates,
  Associates : Associates,
  Restricts : Restricts,
  Statics : Statics,
  Forbids : Forbids,
  Accessors : Accessors,

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
_.Verbal.mixin( Self );
_global_[ Self.name ] = _[ Self.shortName ] = Self;

// --
// export
// --

if( typeof module !== 'undefined' )
if( _global_.WTOOLS_PRIVATE )
delete require.cache[ module.id ];

if( typeof module !== 'undefined' && module !== null )
module[ 'exports' ] = Self;

})();
