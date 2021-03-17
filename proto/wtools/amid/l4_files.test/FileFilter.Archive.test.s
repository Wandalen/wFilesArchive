( function _FileFilter_Archive_test_s_()
{

'use strict';

let waitSync;
if( typeof module !== 'undefined' )
{

  let _ = require( '../../../wtools/Tools.s' );

  _.include( 'wFiles' );
  _.include( 'wTesting' );
  _.include( 'wFilesArchive' );

  waitSync = require( 'wait-sync' );
}

//

let _ = _global_.wTools;
let Parent = wTester;

//

function onSuiteBegin()
{
  if( Config.interpreter === 'njs' )
  this.testRootDirectory = _.path.tempOpen( _.path.join( __dirname, '../..' ), 'Archive' );
  else
  this.testRootDirectory = _.path.current();

  this.delay = _.fileProvider.systemBitrateTimeGet() / 1000;
}

//

function onSuiteEnd()
{
  if( Config.interpreter === 'njs' )
  {
    _.assert( _.strHas( this.testRootDirectory, 'Archive' ) )
    _.fileProvider.fieldPush( 'safe', 0 );
    _.fileProvider.filesDelete( this.testRootDirectory );
    _.fileProvider.fieldPop( 'safe', 0 );
  }
}

//

function flatMapFromTree( tree, currentPath, paths )
{

  currentPath = _.scalarFrom( currentPath );

  if( paths === undefined )
  {
    paths = Object.create( null );
  }

  if( !paths[ currentPath ] )
  paths[ currentPath ] = Object.create( null );

  for( var k in tree )
  {
    if( _.objectIs( tree[ k ] ) )
    {
      paths[ _.path.resolve( currentPath, k ) ] = Object.create( null );

      flatMapFromTree( tree[ k ], _.path.join( currentPath, k ), paths );
    }
    else
    paths[ _.path.resolve( currentPath, k ) ] = tree[ k ];
  }

  return paths;
}

//

function archive( test )
{
  var testRoutineDir = _.path.join( this.testRootDirectory, test.name );
  _.fileProvider.fieldPush( 'safe', 0 );

  test.case = 'multilevel files tree';

  /* prepare tree */

  var filesTree =
  {
    a  :
    {
      b  :
      {
        c  :
        {
          d :
          {
            a  : '1',
            b  : '2',
            c  : '3'
          },
        },
      },
    },
  }

  _.fileProvider.filesDelete({ filePath : testRoutineDir, throwing : 0 });

  _.FileProvider.Extract
  ({
    filesTree,
  })
  .filesReflectTo
  ({
    dst : testRoutineDir,
    dstProvider : _.fileProvider,
  });

  var provider = _.FileFilter.Archive();
  provider.archive.basePath = testRoutineDir;
  provider.archive.verbosity = 0;
  provider.archive.fileMapAutosaving = 1;
  provider.archive.filesUpdate();

  /* check if map contains expected files */

  var flatMap = flatMapFromTree( filesTree, provider.archive.basePath );
  var got = _.mapOnlyOwnKeys( provider.archive.fileMap );
  var expected = _.mapOnlyOwnKeys( flatMap );
  test.true( _.arraySetIdentical( got, expected ) );

  /* check if each file from map has some info inside */

  var allFilesHaveInfo = true;
  got.forEach( ( path ) =>
  {
    var info = provider.archive.fileMap[ path ];
    allFilesHaveInfo &= _.mapOnlyOwnKeys( info ).length > 0;
  } );
  test.true( allFilesHaveInfo );

  /* check how archive saves fileMap of disk */

  var archivePath = _.path.join( provider.archive.basePath, provider.archive.storageFileName );
  var savedOnDisk = !!provider.statResolvedRead( archivePath );
  test.true( savedOnDisk );
  var archive = provider.fileReadJs( archivePath );
  logger.log( _.entityDiff( archive, provider.archive.fileMap ) )
  test.identical( archive, provider.archive.fileMap );

  _.fileProvider.fieldPop( 'safe', 0 );
}

//

function restoreLinks( test )
{
  var testRoutineDir = _.path.join( this.testRootDirectory, test.name );
  _.fileProvider.fieldPush( 'safe', 0 );

  var provider = _.FileFilter.Archive();
  provider.archive.basePath = testRoutineDir;
  provider.archive.verbosity = 0;
  provider.archive.fileMapAutosaving = 0;
  provider.archive.comparingRelyOnHardLinks = 1;

  let hardLinked = true;

  if( provider.original instanceof _.FileProvider.HardDrive )
  if( !provider.original.UsingBigIntForStat )
  hardLinked = _.maybe;

  /* */

  test.case = 'three files linked, first link will be broken';
  provider.filesDelete({ filePath : testRoutineDir, throwing : 0 });
  var paths = [ 'a', 'b', 'c' ];
  paths.forEach( ( p, i ) =>
  {
    paths[ i ] = _.path.join( testRoutineDir, p );
    provider.fileWrite( paths[ i ], 'abc' );
  } );
  provider.hardLink({ dstPath : paths });
  test.identical( provider.areHardLinked( paths ), hardLinked );
  provider.archive.restoreLinksBegin();
  provider.fileTouch({ filePath : paths[ 0 ], purging : 1 });
  waitSync( test.context.delay );
  test.identical( provider.areHardLinked( paths[ 1 ], paths[ 2 ] ), hardLinked );
  test.identical( provider.areHardLinked( paths[ 1 ], paths[ 0 ] ), false );
  test.identical( provider.areHardLinked( paths ), false );
  provider.archive.restoreLinksEnd();
  test.identical( provider.areHardLinked( paths[ 1 ], paths[ 2 ] ), hardLinked );
  test.identical( provider.areHardLinked( paths[ 1 ], paths[ 0 ] ), hardLinked );
  test.identical( provider.areHardLinked( paths ), hardLinked );
  test.identical( provider.fileRead( paths[ 0 ] ), 'abc' );

  /* */

  test.case = 'three files linked, 0 link will be broken, content 0 changed';
  provider.filesDelete({ filePath : testRoutineDir, throwing : 0 });
  var paths = [ 'a', 'b', 'c' ];
  paths.forEach( ( p, i ) =>
  {
    paths[ i ] = _.path.join( testRoutineDir, p );
    provider.fileWrite( paths[ i ], 'abc' );
  } );
  provider.hardLink({ dstPath : paths });
  test.identical( provider.areHardLinked( paths ), hardLinked );
  provider.archive.restoreLinksBegin();
  test.identical( provider.areHardLinked( paths ), hardLinked );
  provider.archive.restoreLinksEnd();
  test.identical( provider.areHardLinked( paths ), hardLinked );
  test.identical( provider.areHardLinked( paths[ 0 ], paths[ 1 ] ), hardLinked );
  test.identical( provider.areHardLinked( paths[ 1 ], paths[ 2 ] ), hardLinked );
  test.identical( provider.fileRead( paths[ 0 ] ), 'abc' );

  /* */

  test.case = 'three files linked, 1 link will be broken, content 1 changed';
  provider.filesDelete( testRoutineDir );
  var paths = [ 'a', 'b', 'c' ];
  paths.forEach( ( p, i ) =>
  {
    paths[ i ] = _.path.join( testRoutineDir, p );
    provider.fileWrite( paths[ i ], 'abc' );
  } );
  provider.hardLink({ dstPath : paths });
  test.identical( provider.areHardLinked( paths ), hardLinked );
  provider.archive.restoreLinksBegin();
  provider.fileTouch({ filePath : paths[ 0 ], purging : 1 });
  waitSync( test.context.delay );
  provider.fileWrite( paths[ 1 ], 'bcd' );
  test.identical( provider.areHardLinked( paths[ 1 ], paths[ 2 ] ), hardLinked );
  test.identical( provider.areHardLinked( paths[ 1 ], paths[ 0 ] ), false );
  test.identical( provider.areHardLinked( paths ), false );
  provider.archive.restoreLinksEnd();
  test.identical( provider.areHardLinked( paths ), hardLinked );
  test.identical( provider.areHardLinked( paths[ 0 ], paths[ 1 ] ), hardLinked );
  test.identical( provider.areHardLinked( paths[ 1 ], paths[ 2 ] ), hardLinked );
  test.identical( provider.fileRead( paths[ 0 ] ), 'bcd' );

  /* */

  test.case = 'three files linked, 0 link will be broken, content 2 changed';
  provider.filesDelete({ filePath : testRoutineDir, throwing : 0 });
  var paths = [ 'a', 'b', 'c' ];
  paths.forEach( ( p, i ) =>
  {
    paths[ i ] = _.path.join( testRoutineDir, p );
    provider.fileWrite( paths[ i ], 'abc' );
  } );
  provider.hardLink({ dstPath : paths });
  test.identical( provider.areHardLinked( paths ), hardLinked );
  provider.archive.restoreLinksBegin();
  provider.fileTouch({ filePath : paths[ 0 ], purging : 1 });
  waitSync( test.context.delay );
  provider.fileWrite( paths[ 2 ], 'bcd' );
  test.identical( provider.areHardLinked( paths[ 1 ], paths[ 2 ] ), hardLinked );
  test.identical( provider.areHardLinked( paths[ 1 ], paths[ 0 ] ), false );
  test.identical( provider.areHardLinked( paths ), false );
  provider.archive.restoreLinksEnd();
  test.identical( provider.areHardLinked( paths ), hardLinked );
  test.identical( provider.areHardLinked( paths[ 0 ], paths[ 1 ] ), hardLinked );
  test.identical( provider.areHardLinked( paths[ 1 ], paths[ 2 ] ), hardLinked );
  test.identical( provider.fileRead( paths[ 0 ] ), 'bcd' );

  /* */

  test.case = 'three files linked, 2 link will be broken, content 0 changed';
  provider.filesDelete({ filePath : testRoutineDir, throwing : 0 });
  var paths = [ 'a', 'b', 'c' ];
  paths.forEach( ( p, i ) =>
  {
    paths[ i ] = _.path.join( testRoutineDir, p );
    provider.fileWrite( paths[ i ], 'abc' );
  } );
  provider.hardLink({ dstPath : paths });
  test.identical( provider.areHardLinked( paths ), hardLinked );
  provider.archive.restoreLinksBegin();
  provider.fileTouch({ filePath : paths[ 2 ], purging : 1 });
  waitSync( test.context.delay );
  provider.fileWrite( paths[ 0 ], 'bcd' );
  test.identical( provider.areHardLinked( paths[ 1 ], paths[ 2 ] ), false );
  test.identical( provider.areHardLinked( paths[ 1 ], paths[ 0 ] ), hardLinked );
  test.identical( provider.areHardLinked( paths ), false );
  provider.archive.restoreLinksEnd();
  test.identical( provider.areHardLinked( paths ), hardLinked );
  test.identical( provider.areHardLinked( paths[ 0 ], paths[ 1 ] ), hardLinked );
  test.identical( provider.areHardLinked( paths[ 1 ], paths[ 2 ] ), hardLinked );
  test.identical( provider.fileRead( paths[ 0 ] ), 'bcd' );

  /* */

  test.case = 'three files linked, 2 link will be broken, content 1 changed';
  provider.filesDelete({ filePath : testRoutineDir, throwing : 0 });
  var paths = [ 'a', 'b', 'c' ];
  paths.forEach( ( p, i ) =>
  {
    paths[ i ] = _.path.join( testRoutineDir, p );
    provider.fileWrite( paths[ i ], 'abc' );
  } );
  provider.hardLink({ dstPath : paths });
  test.identical( provider.areHardLinked( paths ), hardLinked );
  provider.archive.restoreLinksBegin();
  provider.fileTouch({ filePath : paths[ 2 ], purging : 1 });
  waitSync( test.context.delay );
  provider.fileWrite( paths[ 1 ], 'bcd' );
  test.identical( provider.areHardLinked( paths[ 1 ], paths[ 2 ] ), false );
  test.identical( provider.areHardLinked( paths[ 1 ], paths[ 0 ] ), hardLinked );
  test.identical( provider.areHardLinked( paths ), false );
  provider.archive.restoreLinksEnd();
  test.identical( provider.areHardLinked( paths ), hardLinked );
  test.identical( provider.areHardLinked( paths[ 0 ], paths[ 1 ] ), hardLinked );
  test.identical( provider.areHardLinked( paths[ 1 ], paths[ 2 ] ), hardLinked );
  test.identical( provider.fileRead( paths[ 0 ] ), 'bcd' );

  /* */

  test.case = 'three files linked, 2 link will be broken, content 2 changed';
  provider.filesDelete({ filePath : testRoutineDir, throwing : 0 });
  var paths = [ 'a', 'b', 'c' ];
  paths.forEach( ( p, i ) =>
  {
    paths[ i ] = _.path.join( testRoutineDir, p );
    provider.fileWrite( paths[ i ], 'abc' );
  } );
  provider.hardLink({ dstPath : paths });
  test.identical( provider.areHardLinked( paths ), hardLinked );
  provider.archive.restoreLinksBegin();
  provider.fileTouch({ filePath : paths[ 2 ], purging : 1 });
  waitSync( test.context.delay );
  provider.fileWrite( paths[ 2 ], 'bcd' );
  test.identical( provider.areHardLinked( paths[ 1 ], paths[ 2 ] ), false );
  test.identical( provider.areHardLinked( paths[ 1 ], paths[ 0 ] ), hardLinked );
  test.identical( provider.areHardLinked( paths ), false );
  provider.archive.restoreLinksEnd();
  test.identical( provider.areHardLinked( paths ), hardLinked );
  test.identical( provider.areHardLinked( paths[ 0 ], paths[ 1 ] ), hardLinked );
  test.identical( provider.areHardLinked( paths[ 1 ], paths[ 2 ] ), hardLinked );
  test.identical( provider.fileRead( paths[ 0 ] ), 'bcd' );

  /* */

  test.case = 'three files linked, all links will be broken';
  provider.filesDelete( testRoutineDir );
  var paths = [ 'a', 'b', 'c' ];
  paths.forEach( ( p, i ) =>
  {
    paths[ i ] = _.path.join( testRoutineDir, p );
    provider.fileWrite( paths[ i ], 'abc' );
  } );
  provider.hardLink({ dstPath : paths });
  provider.archive.restoreLinksBegin();
  paths.forEach( ( p, i ) =>
  {
    provider.fileTouch({ filePath : p, purging : 1 });
    waitSync( test.context.delay );
    provider.fileWrite( p, '' + i );
  } )
  test.identical( provider.fileRead( paths[ 0 ] ), '0' );
  test.identical( provider.fileRead( paths[ 1 ] ), '1' );
  test.identical( provider.fileRead( paths[ 2 ] ), '2' );
  test.identical( provider.areHardLinked( paths ), false );
  provider.archive.restoreLinksEnd();
  test.identical( provider.areHardLinked( paths ), hardLinked );
  test.identical( provider.areHardLinked( paths[ 0 ], paths[ 1 ] ), hardLinked );
  test.identical( provider.areHardLinked( paths[ 1 ], paths[ 2 ] ), hardLinked );
  test.identical( provider.fileRead( paths[ 0 ] ), '2' );
  test.identical( provider.fileRead( paths[ 1 ] ), '2' );
  test.identical( provider.fileRead( paths[ 2 ] ), '2' );

  /* */

  test.case = 'three files linked, size of first is changed after breaking the link, write 1 last'
  var paths = [ 'a', 'b', 'c' ];
  provider.filesDelete( testRoutineDir );
  paths.forEach( ( p, i ) =>
  {
    paths[ i ] = _.path.join( testRoutineDir, p );
    provider.fileWrite( paths[ i ], 'abc' );
  } );
  provider.hardLink({ dstPath : paths });
  provider.archive.restoreLinksBegin();
  provider.fileTouch({ filePath : paths[ 0 ], purging : 1 });
  waitSync( test.context.delay );
  provider.fileWrite( paths[ 0 ], 'abcd0' );
  waitSync( test.context.delay );
  provider.fileWrite( paths[ 1 ], 'abcd1' );
  test.identical( provider.areHardLinked( paths ), false );
  provider.archive.restoreLinksEnd();
  test.identical( provider.areHardLinked( paths[ 0 ], paths[ 1 ] ), hardLinked );
  test.identical( provider.areHardLinked( paths[ 1 ], paths[ 2 ] ), hardLinked );
  test.identical( provider.fileRead( paths[ 0 ] ), 'abcd1' );
  test.identical( provider.fileRead( paths[ 1 ] ), 'abcd1' );
  test.identical( provider.fileRead( paths[ 2 ] ), 'abcd1' );

  /* */

  test.case = 'three files linked, size of first is changed after breaking the link, write 0 last'
  var paths = [ 'a', 'b', 'c' ];
  provider.filesDelete( testRoutineDir );
  paths.forEach( ( p, i ) =>
  {
    paths[ i ] = _.path.join( testRoutineDir, p );
    provider.fileWrite( paths[ i ], 'abc' );
  } );
  provider.hardLink({ dstPath : paths });
  provider.archive.restoreLinksBegin();
  provider.fileTouch({ filePath : paths[ 0 ], purging : 1 });
  waitSync( test.context.delay );
  provider.fileWrite( paths[ 1 ], 'abcd1' );
  waitSync( test.context.delay );
  provider.fileWrite( paths[ 0 ], 'abcd0' );
  test.identical( provider.areHardLinked( paths ), false );
  provider.archive.restoreLinksEnd();
  test.identical( provider.areHardLinked( paths[ 0 ], paths[ 1 ] ), hardLinked );
  test.identical( provider.areHardLinked( paths[ 1 ], paths[ 2 ] ), hardLinked );
  test.identical( provider.fileRead( paths[ 0 ] ), 'abcd0' );
  test.identical( provider.fileRead( paths[ 1 ] ), 'abcd0' );
  test.identical( provider.fileRead( paths[ 2 ] ), 'abcd0' );

  /* */

  test.case = 'three files linked, fourth is linked with the third file';
  provider.filesDelete( testRoutineDir );
  var paths = [ 'a', 'b', 'c' ];
  paths.forEach( ( p, i ) =>
  {
    paths[ i ] = _.path.join( testRoutineDir, p );
    provider.fileWrite( paths[ i ], 'abc' );
  } );
  provider.hardLink({ dstPath : paths });

  /* linking fourth with second and saving info */

  paths[ 3 ] = _.path.join( testRoutineDir, 'e' );
  provider.hardLink( paths[ 3 ], paths[ 2 ] );
  provider.archive.restoreLinksBegin();

  /*  breaking linkage and changing it content */

  provider.fileWrite({ filePath : paths[ 0 ], purging : 1, data : 'bcd' });
  waitSync( test.context.delay );

  /*  checking if linkage is broken  */

  test.identical( provider.areHardLinked( paths ), false );
  test.identical( provider.areHardLinked( paths[ 0 ], paths[ 1 ] ), false );
  test.identical( provider.areHardLinked( paths[ 1 ], paths[ 2 ] ), hardLinked );
  test.identical( provider.areHardLinked( paths[ 2 ], paths[ 3 ] ), hardLinked );
  test.true( provider.fileRead( paths[ 0 ] ) !== provider.fileRead( paths[ 3 ] ) );
  test.identical( provider.fileRead( paths[ 2 ] ), provider.fileRead( paths[ 3 ] ) );

  /*  restoring linkage  */

  provider.archive.restoreLinksEnd();
  test.identical( provider.areHardLinked( paths ), hardLinked );

  var provider = _.FileFilter.Archive();
  provider.archive.basePath = testRoutineDir;
  provider.archive.verbosity = 0;
  provider.archive.fileMapAutosaving = 0;
  provider.archive.comparingRelyOnHardLinks = 1;
  provider.resolvingSoftLink = 1;

  test.case = 'three files linked, size of file is changed';
  var paths = [ 'a', 'b', 'c' ];
  provider.filesDelete( testRoutineDir );
  paths.forEach( ( p, i ) =>
  {
    paths[ i ] = _.path.join( testRoutineDir, p );
    provider.fileWrite( paths[ i ], 'abc' );
  } );
  provider.hardLink({ dstPath : paths });
  provider.archive.restoreLinksBegin();
  provider.fileTouch({ filePath : paths[ 0 ], purging : 1 });
  waitSync( test.context.delay );
  /* changing size of a file */
  provider.fileWrite( paths[ 0 ], 'abcd' );
  provider.archive.restoreLinksEnd();
  /* checking if link was recovered by comparing content of a files */
  test.identical( provider.areHardLinked( paths ), hardLinked );

  /* */

  test.case = 'three files linked, changing content of a file, but saving size';
  var paths = [ 'a', 'b', 'c' ];
  provider.filesDelete( testRoutineDir );
  paths.forEach( ( p, i ) =>
  {
    paths[ i ] = _.path.join( testRoutineDir, p );
    provider.fileWrite( paths[ i ], 'abc' );
  } );
  provider.hardLink({ dstPath : paths });
  provider.archive.restoreLinksBegin();
  provider.fileTouch({ filePath : paths[ 0 ], purging : 1 });
  waitSync( test.context.delay );
  /* changing size of a file */
  provider.fileWrite( paths[ 0 ], 'cad' );
  provider.archive.restoreLinksEnd();
  /* checking if link was recovered by comparing content of a files */
  test.identical( provider.areHardLinked( paths ), hardLinked );

  _.fileProvider.fieldPop( 'safe', 0 );

}

restoreLinks.timeOut = 30000;

//

function restoreLinksOnDifferentDirLevels( test )
{
  var testRoutineDir = _.path.join( this.testRootDirectory, test.name );
  _.fileProvider.fieldPush( 'safe', 0 );

  var provider = _.FileFilter.Archive();
  provider.archive.fileMapAutosaving = 1;
  provider.archive.allowingMissed = 1;
  provider.archive.allowingCycled = 1;

  let hardLinked = true;
  if( provider.original instanceof _.FileProvider.HardDrive )
  if( !provider.original.UsingBigIntForStat )
  hardLinked = _.maybe;

  /* */

  test.case = 'three files linked, first link will be broken';
  provider.filesDelete({ filePath : testRoutineDir, throwing : 0 });
  var paths1 = [ '..', '.', 'c' ];
  paths1.forEach( ( p, i ) =>
  {
    paths1[ i ] = _.path.join( testRoutineDir, p );
  });
  var paths = [ '../a', 'b', 'c/a' ];
  paths.forEach( ( p, i ) =>
  {
    paths[ i ] = _.path.join( testRoutineDir, p );
    provider.fileWrite( paths[ i ], 'abc' );
  });
  provider.hardLink({ dstPath : paths });
  test.identical( provider.areHardLinked( paths ), hardLinked );

  provider.archive.basePath = paths1;
  provider.archive.restoreLinksBegin();

  provider.fileTouch({ filePath : paths[ 0 ], purging : 1 });
  waitSync( test.context.delay );
  test.identical( provider.areHardLinked( paths[ 1 ], paths[ 2 ] ), hardLinked );
  test.identical( provider.areHardLinked( paths[ 1 ], paths[ 0 ] ), false );
  test.identical( provider.areHardLinked( paths ), false );

  provider.archive.restoreLinksEnd();
  test.identical( provider.areHardLinked( paths[ 1 ], paths[ 2 ] ), hardLinked );
  test.identical( provider.areHardLinked( paths[ 1 ], paths[ 0 ] ), hardLinked );
  test.identical( provider.areHardLinked( paths ), hardLinked );
  test.identical( provider.fileRead( paths[ 0 ] ), 'abc' );
}

//

function restoreLinksComplex( test )
{

  var testRoutineDir = _.path.join( this.testRootDirectory, test.name );
  _.fileProvider.fieldPush( 'safe', 0 );

  var provider = _.FileFilter.Archive({ original : new _.FileProvider.Default() });
  provider.verbosity = 0;
  provider.archive.verbosity = 0;
  provider.archive.basePath = testRoutineDir;
  provider.archive.fileMapAutosaving = 0;
  provider.archive.comparingRelyOnHardLinks = 0;

  run();

  var provider = _.FileFilter.Archive();
  provider.archive.basePath = testRoutineDir;
  provider.archive.verbosity = 0;
  provider.archive.fileMapAutosaving = 0;
  provider.archive.comparingRelyOnHardLinks = 1;

  run();

  /* */

  function begin()
  {
    var files = {};
    var _files =
    {
      'a1' : '3', /* 0 */
      'a2' : '3', /* 1 */
      'a3' : '3', /* 2 */
      'b1' : '5', /* 3 */
      'b2' : '5', /* 4 */
      'b3' : '5', /* 5 */
      'c1' : '8', /* 6 */
      'd1' : '8', /* 7 */
    };
    provider.filesDelete( testRoutineDir );
    _.each( _files, ( e, k ) =>
    {
      k = _.path.join( testRoutineDir, k );
      files[ k ] = e;
      waitSync( test.context.delay )
      provider.fileWrite( k, e );
    } );

    return files;
  }

  /* */

  function run()
  {
    let hardLinked = true;

    if( provider.original instanceof _.FileProvider.HardDrive )
    if( !provider.original.UsingBigIntForStat )
    hardLinked = _.maybe;

    test.case = 'complex case, no content changing';
    var files = begin();

    /* make links and save info in archive */

    provider.hardLink({ dstPath : _.mapKeys( files ).slice( 0, 3 ), verbosity : 3 });
    provider.hardLink({ dstPath : _.mapKeys( files ).slice( 3, 6 ), verbosity : 3 });
    test.identical( provider.areHardLinked( _.mapKeys( files ).slice( 0, 3 ) ), hardLinked );
    test.identical( provider.areHardLinked( _.mapKeys( files ).slice( 3, 6 ) ), hardLinked );
    test.identical( provider.areHardLinked( _.mapKeys( files ).slice( 0, 6 ) ), false );
    test.identical( provider.areHardLinked( _.mapKeys( files ).slice( 6, 8 ) ), false );


    provider.archive.restoreLinksBegin();

    /* remove some links and check if they are broken */

    waitSync( test.context.delay )
    provider.fileWrite({ filePath : _.mapKeys( files )[ 0 ], purging : 1, data : 'a' });
    waitSync( test.context.delay )
    provider.fileWrite({ filePath : _.mapKeys( files )[ 3 ], purging : 1, data : 'b' });
    waitSync( test.context.delay )
    provider.fileWrite({ filePath : _.mapKeys( files )[ 6 ], purging : 0, data : 'd' });
    test.identical( provider.areHardLinked( _.mapKeys( files ).slice( 0, 3 ) ), false );
    test.identical( provider.areHardLinked( _.mapKeys( files ).slice( 3, 8 ) ), false );
    test.identical( provider.fileRead( _.mapKeys( files )[ 0 ] ), 'a' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 1 ] ), '3' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 2 ] ), '3' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 3 ] ), 'b' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 4 ] ), '5' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 5 ] ), '5' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 6 ] ), 'd' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 7 ] ), '8' );

    /* restore links and check if they works now */

    var records1 = provider.recordFactory().records( _.mapKeys( files ).slice( 0, 3 ) );
    var records2 = provider.recordFactory().records( _.mapKeys( files ).slice( 3, 6 ) );

    logger.log( _.select( records1, '*/stat/mtime' ).map( ( t ) => t.getTime() ) )
    logger.log( _.select( records2, '*/stat/mtime' ).map( ( t ) => t.getTime() ) )

    provider.archive.restoreLinksEnd();

    test.identical( provider.archive.verbosity, 0 );
    test.identical( provider.archive.replacingByNewest, 1 );
    test.identical( provider.archive.fileMapAutosaving, 0 );
    test.identical( provider.archive.storageFileName, '.warchive' );
    // test.identical( provider.archive.dependencyMap, {} );
    // test.identical( provider.archive.fileByHashMap, {} );
    test.identical( provider.archive.fileAddedMap, {} );
    test.identical( provider.archive.fileRemovedMap, {} );
    test.identical( provider.archive.fileAddedMap, {} );
    test.identical( _.mapKeys( provider.archive.fileMap ).length, 9 );

    //!!!wrong results on linux

    // if( provider.archive.comparingRelyOnHardLinks )
    // {
    //   test.identical( provider.archive.comparingRelyOnHardLinks, 1 );
    //   test.identical( _.mapKeys( provider.archive.fileModifiedMap ).length, 8 );
    // }
    // else
    // {
    //   test.identical( provider.archive.comparingRelyOnHardLinks, 0 );
    //   test.identical( _.mapKeys( provider.archive.fileModifiedMap ).length, 4 );
    // }

    test.identical( provider.areHardLinked( _.mapKeys( files ).slice( 0, 3 ) ), hardLinked );
    test.identical( provider.areHardLinked( _.mapKeys( files ).slice( 3, 6 ) ), hardLinked );
    test.identical( provider.areHardLinked( _.mapKeys( files ).slice( 0, 6 ) ), false );
    test.identical( provider.areHardLinked( _.mapKeys( files ).slice( 6, 8 ) ), false );
    test.identical( provider.fileRead( _.mapKeys( files )[ 0 ] ), 'a' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 1 ] ), 'a' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 2 ] ), 'a' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 3 ] ), 'b' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 4 ] ), 'b' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 5 ] ), 'b' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 6 ] ), 'd' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 7 ] ), '8' );

    //

    test.case = 'complex case, different content change';
    var files = begin();

    /* make links and save info in archive */

    provider.hardLink({ dstPath : _.mapKeys( files ).slice( 0, 3 ), verbosity : 3 });
    provider.hardLink({ dstPath : _.mapKeys( files ).slice( 3, 6 ), verbosity : 3 });
    test.identical( provider.areHardLinked( _.mapKeys( files ).slice( 0, 3 ) ), hardLinked );
    test.identical( provider.areHardLinked( _.mapKeys( files ).slice( 3, 6 ) ), hardLinked );
    test.identical( provider.areHardLinked( _.mapKeys( files ).slice( 0, 6 ) ), false );
    test.identical( provider.areHardLinked( _.mapKeys( files ).slice( 6, 8 ) ), false );

    provider.archive.restoreLinksBegin();

    /* remove some links and check if they are broken */

    waitSync( test.context.delay )
    provider.fileWrite({ filePath : _.mapKeys( files )[ 0 ], purging : 1, data : 'a1' });
    waitSync( test.context.delay )
    provider.fileWrite({ filePath : _.mapKeys( files )[ 1 ], purging : 1, data : 'a2' });
    test.identical( provider.areHardLinked( _.mapKeys( files ).slice( 0, 3 ) ), false );
    test.identical( provider.areHardLinked( _.mapKeys( files ).slice( 3, 8 ) ), false );
    test.identical( provider.fileRead( _.mapKeys( files )[ 0 ] ), 'a1' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 1 ] ), 'a2' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 2 ] ), '3' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 3 ] ), '5' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 4 ] ), '5' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 5 ] ), '5' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 6 ] ), '8' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 7 ] ), '8' );

    /* restore links and check if they works now */

    provider.verbosity = 2;
    provider.archive.verbosity = 2;
    provider.archive.restoreLinksEnd();
    provider.verbosity = 0;
    provider.archive.verbosity = 0;

    test.identical( provider.archive.verbosity, 0 );
    test.identical( provider.archive.replacingByNewest, 1 );
    test.identical( provider.archive.fileMapAutosaving, 0 );
    test.identical( provider.archive.storageFileName, '.warchive' );
    // test.identical( provider.archive.dependencyMap, {} );
    // test.identical( provider.archive.fileByHashMap, {} );
    test.identical( provider.archive.fileAddedMap, {} );
    test.identical( provider.archive.fileRemovedMap, {} );
    test.identical( provider.archive.fileAddedMap, {} );
    test.identical( _.mapKeys( provider.archive.fileMap ).length, 9 );

    //!!!wrong results on linux

    /* if( provider.archive.comparingRelyOnHardLinks )
    {
      test.identical( provider.archive.comparingRelyOnHardLinks, 1 );
      test.identical( _.mapKeys( provider.archive.fileModifiedMap ).length, 4 );
    }
    else
    {
      test.identical( provider.archive.comparingRelyOnHardLinks, 0 );
      test.identical( _.mapKeys( provider.archive.fileModifiedMap ).length, 3 );
    } */

    test.identical( provider.areHardLinked( _.mapKeys( files ).slice( 0, 3 ) ), hardLinked );
    test.identical( provider.areHardLinked( _.mapKeys( files ).slice( 3, 6 ) ), hardLinked );
    test.identical( provider.areHardLinked( _.mapKeys( files ).slice( 0, 6 ) ), false );
    test.identical( provider.areHardLinked( _.mapKeys( files ).slice( 6, 8 ) ), false );
    test.identical( provider.fileRead( _.mapKeys( files )[ 0 ] ), 'a2' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 1 ] ), 'a2' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 2 ] ), 'a2' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 3 ] ), '5' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 4 ] ), '5' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 5 ] ), '5' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 6 ] ), '8' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 7 ] ), '8' );

    //

    test.case = 'complex case, no content changing';
    var files = begin();

    /* make links and save info in archive */

    provider.hardLink({ dstPath : _.mapKeys( files ).slice( 0, 3 ), verbosity : 3 });
    provider.hardLink({ dstPath : _.mapKeys( files ).slice( 3, 6 ), verbosity : 3 });
    test.identical( provider.areHardLinked( _.mapKeys( files ).slice( 0, 3 ) ), hardLinked );
    test.identical( provider.areHardLinked( _.mapKeys( files ).slice( 3, 6 ) ), hardLinked );
    test.identical( provider.areHardLinked( _.mapKeys( files ).slice( 0, 6 ) ), false );
    test.identical( provider.areHardLinked( _.mapKeys( files ).slice( 6, 8 ) ), false );

    provider.archive.restoreLinksBegin();

    /* remove some links and check if they are broken */

    provider.fileWrite({ filePath : _.mapKeys( files )[ 0 ], purging : 1, data : 'a' });
    waitSync( test.context.delay );
    provider.fileWrite({ filePath : _.mapKeys( files )[ 3 ], purging : 1, data : 'b' });
    waitSync( test.context.delay );
    provider.fileWrite({ filePath : _.mapKeys( files )[ 4 ], purging : 0, data : 'c' });
    waitSync( test.context.delay );
    provider.fileWrite({ filePath : _.mapKeys( files )[ 6 ], purging : 0, data : 'd' });

    test.identical( provider.areHardLinked( _.mapKeys( files ).slice( 0, 3 ) ), false );
    test.identical( provider.areHardLinked( _.mapKeys( files ).slice( 3, 8 ) ), false );
    test.identical( provider.fileRead( _.mapKeys( files )[ 0 ] ), 'a' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 1 ] ), '3' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 2 ] ), '3' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 3 ] ), 'b' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 4 ] ), 'c' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 5 ] ), 'c' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 6 ] ), 'd' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 7 ] ), '8' );

    /* restore links and check if they works now */

    provider.archive.restoreLinksEnd();

    test.identical( provider.archive.verbosity, 0 );
    test.identical( provider.archive.replacingByNewest, 1 );
    test.identical( provider.archive.fileMapAutosaving, 0 );
    test.identical( provider.archive.storageFileName, '.warchive' );
    // test.identical( provider.archive.dependencyMap, {} );
    // test.identical( provider.archive.fileByHashMap, {} );
    test.identical( provider.archive.fileAddedMap, {} );
    test.identical( provider.archive.fileRemovedMap, {} );
    test.identical( provider.archive.fileAddedMap, {} );
    test.identical( _.mapKeys( provider.archive.fileMap ).length, 9 );

    //!!!wrong results on linux

    /* if( provider.archive.comparingRelyOnHardLinks )
    {
      test.identical( provider.archive.comparingRelyOnHardLinks, 1 );
      test.identical( _.mapKeys( provider.archive.fileModifiedMap ).length, 8 );
    }
    else
    {
      test.identical( provider.archive.comparingRelyOnHardLinks, 0 );
      test.identical( _.mapKeys( provider.archive.fileModifiedMap ).length, 6 );
    } */

    test.identical( provider.areHardLinked( _.mapKeys( files ).slice( 0, 3 ) ), hardLinked );
    test.identical( provider.areHardLinked( _.mapKeys( files ).slice( 3, 6 ) ), hardLinked );
    test.identical( provider.areHardLinked( _.mapKeys( files ).slice( 0, 6 ) ), false );
    test.identical( provider.areHardLinked( _.mapKeys( files ).slice( 6, 8 ) ), false );
    test.identical( provider.fileRead( _.mapKeys( files )[ 0 ] ), 'a' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 1 ] ), 'a' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 2 ] ), 'a' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 3 ] ), 'c' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 4 ] ), 'c' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 5 ] ), 'c' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 6 ] ), 'd' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 7 ] ), '8' );

  }


  _.fileProvider.fieldPop( 'safe', 0 );
}

restoreLinksComplex.timeOut = 120000;

//

function filesLinkSame( test )
{
  var context = this;
  var dir = _.path.join( context.testRootDirectory, test.name );
  _.fileProvider.fieldPush( 'safe', 0 );
  var provider;

  let hardLinked;

  function begin()
  {

    test.case = 'prepare';

    _.fileProvider.filesDelete( context.testRootDirectory );

    var filesTree =
    {
      a : '1',
      b : '3',
      c : '1',
      d : '5',
      dir : { a : '1', x : '3' },
    }

    provider = _.FileFilter.Archive();
    provider.archive.basePath = dir;
    provider.archive.fileMapAutosaving = 0;

    // _.FileProvider.Extract.readToProvider
    // ({
    //   filesTree,
    //   dstProvider : provider,
    //   dstPath : dir,
    // });

    _.FileProvider.Extract
    ({
      filesTree,
    })
    .filesReflectTo
    ({
      dst : dir,
      dstProvider : provider,
    });

    test.true( !!provider.statResolvedRead( _.path.join( dir, 'a' ) ) );
    test.true( !!provider.statResolvedRead( _.path.join( dir, 'dir/a' ) ) );

    hardLinked = true;

    if( provider.original instanceof _.FileProvider.HardDrive )
    if( !provider.original.UsingBigIntForStat )
    hardLinked = _.maybe;

  }

  begin();

  test.case = 'consideringFileName : 0';

  provider.archive.filesUpdate();
  provider.archive.filesLinkSame({ consideringFileName : 0 });

  test.true( !!provider.statResolvedRead( _.path.join( dir, 'a' ) ) );
  test.true( !!provider.statResolvedRead( _.path.join( dir, 'dir/a' ) ) );

  test.identical( provider.areHardLinked([ _.path.join( dir, 'a' ), _.path.join( dir, 'b' ) ]), false );
  test.identical( provider.areHardLinked([ _.path.join( dir, 'a' ), _.path.join( dir, 'dir/x' ) ]), false );

  test.identical( provider.areHardLinked([ _.path.join( dir, 'a' ), _.path.join( dir, 'c' ), _.path.join( dir, 'dir/a' ) ]), hardLinked );
  test.identical( provider.areHardLinked([ _.path.join( dir, 'b' ), _.path.join( dir, 'dir/x' ) ]), hardLinked );

  provider.finit();
  provider.archive.finit();

  begin();

  test.case = 'consideringFileName : 1';

  provider.archive.filesUpdate();
  provider.archive.filesLinkSame({ consideringFileName : 1 });

  test.true( !!provider.statResolvedRead( _.path.join( dir, 'a' ) ) );
  test.true( !!provider.statResolvedRead( _.path.join( dir, 'dir/a' ) ) );

  test.identical( provider.areHardLinked([ _.path.join( dir, 'a' ), _.path.join( dir, 'b' ) ]), false );
  test.identical( provider.areHardLinked([ _.path.join( dir, 'a' ), _.path.join( dir, 'dir/x' ) ]), false );

  test.identical( provider.areHardLinked([ _.path.join( dir, 'a' ), _.path.join( dir, 'dir/a' ) ]), hardLinked );
  test.identical( provider.areHardLinked([ _.path.join( dir, 'a' ), _.path.join( dir, 'c' ) ]), false );
  test.identical( provider.areHardLinked([ _.path.join( dir, 'b' ), _.path.join( dir, 'dir/x' ) ]), false );

  provider.finit();
  provider.archive.finit();

  _.fileProvider.fieldPop( 'safe', 0 );
}

//

function filesLinkSameEmptyFiles( test )
{
  var context = this;
  var dir = _.path.join( context.testRootDirectory, test.name );
  _.fileProvider.fieldPush( 'safe', 0 );
  var provider;

  function begin()
  {

    test.case = 'prepare';

    _.fileProvider.filesDelete( context.testRootDirectory );

    var filesTree =
    {
      a : '',
      b : '',
      c : 'c',
      d : 'd',
      e : 'same',
      f : 'same',
      dir : { 'f' : 'same' }
    }

    provider = _.FileFilter.Archive();
    provider.archive.basePath = dir;
    provider.archive.fileMapAutosaving = 0;


    _.FileProvider.Extract
    ({
      filesTree,
    })
    .filesReflectTo
    ({
      dst : dir,
      dstProvider : provider,
    });
  }

  begin();

  test.case = 'consideringFileName : 0';

  provider.archive.filesUpdate();
  provider.archive.filesLinkSame({ consideringFileName : 0 });

  test.true( provider.fileExists( _.path.join( dir, 'a' ) ) );
  test.true( provider.fileExists( _.path.join( dir, 'b' ) ) );
  test.true( provider.fileExists( _.path.join( dir, 'c' ) ) );
  test.true( provider.fileExists( _.path.join( dir, 'd' ) ) );
  test.true( provider.fileExists( _.path.join( dir, 'e' ) ) );
  test.true( provider.fileExists( _.path.join( dir, 'f' ) ) );
  test.true( provider.fileExists( _.path.join( dir, 'dir/f' ) ) );

  test.identical( provider.areHardLinked( _.path.s.join( dir, [ 'a', 'b' ] ) ), false );
  test.identical( provider.areHardLinked( _.path.s.join( dir, [ 'a', 'c' ] ) ), false );
  test.identical( provider.areHardLinked( _.path.s.join( dir, [ 'a', 'd' ] ) ), false );
  test.identical( provider.areHardLinked( _.path.s.join( dir, [ 'a', 'e' ] ) ), false );
  test.identical( provider.areHardLinked( _.path.s.join( dir, [ 'c', 'd' ] ) ), false );
  test.identical( provider.areHardLinked( _.path.s.join( dir, [ 'e', 'f' ] ) ), true );
  test.identical( provider.areHardLinked( _.path.s.join( dir, [ 'e', 'f', 'dir/f' ] ) ), true );

  provider.finit();
  provider.archive.finit();

  begin();

  test.case = 'consideringFileName : 1';

  provider.archive.filesUpdate();
  provider.archive.filesLinkSame({ consideringFileName : 1 });

  test.true( provider.fileExists( _.path.join( dir, 'a' ) ) );
  test.true( provider.fileExists( _.path.join( dir, 'b' ) ) );
  test.true( provider.fileExists( _.path.join( dir, 'c' ) ) );
  test.true( provider.fileExists( _.path.join( dir, 'd' ) ) );
  test.true( provider.fileExists( _.path.join( dir, 'e' ) ) );
  test.true( provider.fileExists( _.path.join( dir, 'f' ) ) );
  test.true( provider.fileExists( _.path.join( dir, 'dir/f' ) ) );

  test.identical( provider.areHardLinked( _.path.s.join( dir, [ 'a', 'b' ] ) ), false );
  test.identical( provider.areHardLinked( _.path.s.join( dir, [ 'a', 'c' ] ) ), false );
  test.identical( provider.areHardLinked( _.path.s.join( dir, [ 'a', 'd' ] ) ), false );
  test.identical( provider.areHardLinked( _.path.s.join( dir, [ 'a', 'e' ] ) ), false );
  test.identical( provider.areHardLinked( _.path.s.join( dir, [ 'c', 'd' ] ) ), false );
  test.identical( provider.areHardLinked( _.path.s.join( dir, [ 'e', 'f' ] ) ), false );
  test.identical( provider.areHardLinked( _.path.s.join( dir, [ 'e', 'dir/f' ] ) ), false );
  test.identical( provider.areHardLinked( _.path.s.join( dir, [ 'f', 'dir/f' ] ) ), true );

  provider.finit();
  provider.archive.finit();

  _.fileProvider.fieldPop( 'safe', 0 );
}

//

function severalPaths( test )
{
  var context = this;
  var dir = _.path.join( context.testRootDirectory, test.name );
  _.fileProvider.fieldPush( 'safe', 0 );
  var provider;

  let hardLinked;

  function begin()
  {

    test.case = 'prepare';

    _.fileProvider.filesDelete( context.testRootDirectory );

    var filesTree =
    {
      dir1 :
      {
        a : '1',
        b : '3',
        c : '1',
        d : '5',
      },
      dir2 :
      {
        a : '1',
        x : '3'
      },
      dir3 :
      {
        x : '3',
      },
    }

    provider = _.FileFilter.Archive();
    provider.archive.basePath = [ _.path.join( dir, 'dir1' ), _.path.join( dir, 'dir2' ), _.path.join( dir, 'dir3' ) ];
    provider.archive.fileMapAutosaving = 0;

    // _.FileProvider.Extract.readToProvider
    // ({
    //   filesTree,
    //   dstProvider : provider,
    //   dstPath : dir,
    // });

    _.FileProvider.Extract
    ({
      filesTree,
    })
    .filesReflectTo
    ({
      dst : dir,
      dstProvider : provider,
    });

    test.true( !!provider.statResolvedRead( _.path.join( dir, 'dir1/a' ) ) );
    test.true( !!provider.statResolvedRead( _.path.join( dir, 'dir2/a' ) ) );
    test.true( !!provider.statResolvedRead( _.path.join( dir, 'dir3/x' ) ) );

    hardLinked = true;

    if( provider.original instanceof _.FileProvider.HardDrive )
    if( !provider.original.UsingBigIntForStat )
    hardLinked = _.maybe;

  }

  begin();

  test.case = 'consideringFileName : 1';

  provider.archive.filesUpdate();
  provider.archive.filesLinkSame({ consideringFileName : 1 });

  test.true( !!provider.statResolvedRead( _.path.join( dir, 'dir1/a' ) ) );
  test.true( !!provider.statResolvedRead( _.path.join( dir, 'dir2/a' ) ) );
  test.true( !!provider.statResolvedRead( _.path.join( dir, 'dir3/x' ) ) );

  test.identical( provider.areHardLinked( [ _.path.join( dir, 'dir1/a' ), _.path.join( dir, 'dir2/a' ) ]), hardLinked );
  test.identical( provider.areHardLinked( [ _.path.join( dir, 'dir2/x' ), _.path.join( dir, 'dir3/x' ) ]), hardLinked );

  test.identical( provider.areHardLinked( [ _.path.join( dir, 'dir1/a' ), _.path.join( dir, 'dir1/b' ) ]), false );
  test.identical( provider.areHardLinked( [ _.path.join( dir, 'dir1/b' ), _.path.join( dir, 'dir2/x' ) ]), false );

  provider.finit();
  provider.archive.finit();

  _.fileProvider.fieldPop( 'safe', 0 );
}

//

function storageOperations( test )
{
  let context = this;
  _.fileProvider.fieldPush( 'safe', 0 );
  let dir = _.path.join( context.testRootDirectory, test.name );

  _.fileProvider.filesDelete( dir );

  let filesTree =
  {
    dir1 :
    {
      a : '1',
      b : '3',
      c : '1',
      d : '5',
    },
    dir2 :
    {
      a : '1',
      x : '3'
    },
    dir3 :
    {
      x : '3',
    },
  }

  var provider = _.FileFilter.Archive();
  provider.archive.basePath = _.path.s.join( dir, [ 'dir1', 'dir2', 'dir3' ] );
  provider.archive.verbosity = 0;
  provider.archive.fileMapAutosaving = 1;
  provider.archive.fileMapAutoLoading = 0;

  _.FileProvider.Extract
  ({
    filesTree,
  })
  .filesReflectTo
  ({
    dst : dir,
    dstProvider : provider,
  });

  provider.archive.filesUpdate();

  test.identical( provider.archive.storagesLoaded, [] );

  var archivePaths = _.path.s.join( dir, [ 'dir1', 'dir2', 'dir3' ], provider.archive.storageFileName );
  var records = provider.recordFactory().records( archivePaths );
  records.forEach( ( r ) =>
  {
    let filesMap = provider.fileRead({ filePath : r.absolute, encoding : 'js.structure' });
    test.description = 'archive saved on disk and fileMap are same';
    test.contains( provider.archive.fileMap, filesMap );
  });

  provider.finit();
  provider.archive.finit();

  /* load->update */

  var provider = _.FileFilter.Archive();
  provider.archive.basePath = _.path.s.join( dir, [ 'dir1', 'dir2', 'dir3' ] );
  provider.archive.verbosity = 0;
  provider.archive.fileMapAutosaving = 0;
  provider.archive.fileMapAutoLoading = 1;

  //simulate file change before filesUpdate
  let time = new Date( 98, 1 );
  provider.timeWrite( _.path.join( dir, 'dir1/a' ), time, time );
  provider.timeWrite( _.path.join( dir, 'dir2/a' ), time, time );
  provider.timeWrite( _.path.join( dir, 'dir3/x' ), time, time );

  provider.archive.filesUpdate();

  var archivePaths = _.path.s.join( dir, [ 'dir1', 'dir2', 'dir3' ], provider.archive.storageFileName );

  test.case = 'storages are loaded from disk';
  var loadedStorages = _.select( provider.archive.storagesLoaded, '*/filePath' );
  test.identical( loadedStorages, archivePaths );

  var filePaths = _.mapOnlyOwnKeys( provider.archive.fileMap );
  records.forEach( ( r ) =>
  {
    let filesMap = provider.fileRead({ filePath : r.absolute, encoding : 'js.structure' });

    test.case = 'archive on disk and fileMap have same files';
    test.true( _.arraySetContainAll_( filePaths, _.mapOnlyOwnKeys( filesMap ) ) );

    // filesMap is not upToDate if at least one file from map was changed
    test.case = 'archive on disk is not updated';
    let upToDate = true;
    for( let filePath in filesMap )
    if( !_.entityIdentical( filesMap[ filePath ], provider.archive.fileMap[ filePath ] ) )
    {
      upToDate = false;
      break;
    }
    test.true( !upToDate );
  });

  provider.finit();
  provider.archive.finit();

  /* load->update->save */

  var provider = _.FileFilter.Archive();
  provider.archive.basePath = _.path.s.join( dir, [ 'dir1', 'dir2', 'dir3' ] );
  provider.archive.verbosity = 0;
  provider.archive.fileMapAutosaving = 1;
  provider.archive.fileMapAutoLoading = 1;

  provider.archive.filesUpdate();

  var archivePaths = _.path.s.join( dir, [ 'dir1', 'dir2', 'dir3' ], provider.archive.storageFileName );
  var loadedStorages = _.select( provider.archive.storagesLoaded, '*/filePath' );
  test.identical( loadedStorages, archivePaths );

  var records = provider.recordFactory().records( archivePaths );
  records.forEach( ( r ) =>
  {
    let filesMap = provider.fileRead({ filePath : r.absolute, encoding : 'js.structure' });
    test.case = 'archive saved on disk and fileMap are same';
    test.contains( provider.archive.fileMap, filesMap );
  });

  provider.finit();
  provider.archive.finit();

  _.fileProvider.fieldPop( 'safe', 0 );
}

//

function inodeExperiment( test )
{
  let context = this;
  _.fileProvider.fieldPush( 'safe', 0 );

  if( Config.interpreter !== 'njs' )
  if( process.platform !== 'win32' )
  {
    test.identical( 1, 1 );
    return;
  }

  let dirname = _.path.join( context.testRootDirectory, test.name );
  let pathsSameIno;

  for( var i = 0; i < 10; i++ )
  {
    pathsSameIno = begin();
    if( pathsSameIno )
    break;
  }

  if( !pathsSameIno )
  {
    if( typeof BigInt === 'undefined' )
    {
      test.case = 'should be two files with same ino';
      test.identical( pathsSameIno.length, 2 );
    }
    else
    {
      test.case = 'should be no files with same ino';
      test.identical( pathsSameIno, undefined );
    }
    return;
  }

  /**/

  var provider = _.FileFilter.Archive();
  provider.archive.basePath = dirname;
  provider.archive.verbosity = 10;
  provider.archive.fileMapAutosaving = 0;
  provider.archive.comparingRelyOnHardLinks = 0;

  provider.archive.restoreLinksBegin();

  test.case = 'files with same ino should not have same hash'
  let hash1 = provider.archive.fileMap[ pathsSameIno[ 0 ] ].hash;
  let hash2 = provider.archive.fileMap[ pathsSameIno[ 1 ] ].hash;
  test.notIdentical( hash1, hash2 );

  test.case = 'files with same ino should not have same hash2'
  hash1 = provider.archive.fileMap[ pathsSameIno[ 0 ] ].hashOfStat;
  hash2 = provider.archive.fileMap[ pathsSameIno[ 1 ] ].hashOfStat;
  test.notIdentical( hash1, hash2 )

  provider.hardLink({ dstPath : pathsSameIno });
  test.identical( provider.areHardLinked.apply( provider, pathsSameIno ), hardLinked )

  provider.archive.restoreLinksEnd();

  test.case = 'restored files should not be linked';
  test.identical( provider.areHardLinked.apply( provider, pathsSameIno ), false )

  test.case = 'restored files should not have same hash';
  hash1 = provider.hashRead( pathsSameIno[ 0 ] );
  hash2 = provider.hashRead( pathsSameIno[ 1 ] );
  test.notIdentical( hash1, hash2 );
  test.case = 'restored files should not be same';
  test.true( !provider.filesCanBeSame.apply( provider, pathsSameIno ) );

  provider.finit();
  provider.archive.finit();

  _.fileProvider.fieldPop( 'safe', 0 );

  /* */

  function begin()
  {
    let inodes = {};
    let pathsSameIno;

    _.fileProvider.filesDelete( dirname );

    for( let i = 0; i < 300; i++ )
    {
      let path = _.path.join( dirname, '' + i );
      _.fileProvider.fileWrite( path, path );
      let stat = _.fileProvider.statResolvedRead( path );
      if( inodes[ stat.ino ] )
      {
        pathsSameIno = [ inodes[ stat.ino ], path ];
        logger.log( 'Inode duplication!' );
        logger.log( _.entity.exportString( pathsSameIno ) );
        break;
      }

      inodes[ stat.ino ] = path;
    }
    return pathsSameIno;
  }
}

inodeExperiment.timeOut = 10000;
inodeExperiment.experimental = 1;

//

function tester( test )
{
  var self = this;

  var suite = test.suite;
  var tests = suite.tests;

  var runsLimit = 5;

  var tests =
  {
    restoreLinksComplex
  }

  for( var t in tests )
  {
    var ok = true;
    for( var i = 0; i < runsLimit; i++ )
    {
      tests[ t ].call( self, test );
      if( test.report.testCheckFails > 0 )
      {
        ok = false;
        break;
      }
    }
    if( !ok )
    break;
  }
}

// --
// declare
// --

let Self =
{

  name : 'Tools.mid.files.src.Archive',
  silencing : 1,
  // verbosity : 4,
  // negativity : 5,
  // routine : 'restoreLinks',

  onSuiteBegin,
  onSuiteEnd,

  context :
  {
    testRootDirectory : null,
    delay : null
  },

  tests :
  {

    archive,
    restoreLinks,
    restoreLinksOnDifferentDirLevels,
    restoreLinksComplex,
    filesLinkSame,
    filesLinkSameEmptyFiles,
    severalPaths,
    storageOperations,
    inodeExperiment,

    // tester,

  },

};

Self = wTestSuite( Self )
if( typeof module !== 'undefined' && !module.parent )
wTester.test( Self.name );

})();
