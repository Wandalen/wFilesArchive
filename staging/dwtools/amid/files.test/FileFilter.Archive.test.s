( function _FileFilter_Archive_test_s_( ) {

'use strict';

var isBrowser = true;
if( typeof module !== 'undefined' )
{
  isBrowser = false;

  if( typeof _global_ === 'undefined' || !_global_.wBase )
  {
    let toolsPath = '../../../dwtools/Base.s';
    let toolsExternal = 0;
    try
    {
      toolsPath = require.resolve( toolsPath );
    }
    catch( err )
    {
      toolsExternal = 1;
      require( 'wTools' );
    }
    if( !toolsExternal )
    require( toolsPath );
  }

  var _ = _global_.wTools;

  _.include( 'wFiles' );
  _.include( 'wTesting' );
  _.include( 'wFilesArchive' );

  var waitSync = require( 'wait-sync' );
}

//

var _ = _global_.wTools;
var Parent = _.Tester;

//

function onSuiteBegin()
{
  if( !isBrowser )
  this.testRootDirectory = _.path.dirTempOpen( _.path.join( __dirname, '../..'  ), 'Archive' );
  else
  this.testRootDirectory = _.path.current();

  this.delay = _.fileProvider.systemBitrateTimeGet() / 1000;
}

//

function onSuiteEnd()
{
  if( !isBrowser )
  {
    _.assert( _.strEnds( this.testRootDirectory, 'Archive' ) )
    _.fileProvider.fieldSet( 'safe', 0 );
    _.fileProvider.filesDelete( this.testRootDirectory );
    _.fileProvider.fieldReset( 'safe', 0 );
  }
}

//

function flatMapFromTree( tree, currentPath, paths )
{
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
  _.fileProvider.fieldSet( 'safe', 0 );

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
  _.FileProvider.Extract.readToProvider
  ({
    filesTree : filesTree,
    dstPath : testRoutineDir,
    dstProvider : _.fileProvider,
  });

  var provider = _.FileFilter.Archive();
  provider.archive.basePath = testRoutineDir;
  provider.archive.verbosity = 0;
  provider.archive.fileMapAutosaving = 1;
  provider.archive.filesUpdate();

  /* check if map contains expected files */

  var flatMap = flatMapFromTree( filesTree, provider.archive.basePath );
  var got = _.mapOwnKeys( provider.archive.fileMap );
  var expected = _.mapOwnKeys( flatMap );
  test.is( _.arraySetIdentical( got, expected ) );

  /* check if each file from map has some info inside */

  var allFilesHaveInfo = true;
  got.forEach( ( path ) =>
  {
    var info = provider.archive.fileMap[ path ];
    allFilesHaveInfo &= _.mapOwnKeys( info ).length > 0;
  });
  test.is( allFilesHaveInfo );

  /* check how archive saves fileMap of disk */

  var archivePath = _.path.join( provider.archive.basePath, provider.archive.storageFileName );
  var savedOnDisk = !!provider.fileStat( archivePath );
  test.is( savedOnDisk );
  var archive = provider.fileReadJs( archivePath );
  logger.log( _.entityDiff(  archive, provider.archive.fileMap ) )
  test.identical( archive, provider.archive.fileMap );


  _.fileProvider.fieldReset( 'safe', 0 );
}

//

function restoreLinks( test )
{
  var testRoutineDir = _.path.join( this.testRootDirectory, test.name );
  _.fileProvider.fieldSet( 'safe', 0 );

  var provider = _.FileFilter.Archive();
  provider.archive.basePath = testRoutineDir;
  provider.archive.verbosity = 0;
  provider.archive.fileMapAutosaving = 0;
  provider.archive.comparingRelyOnHardLinks = 1;

  //

  test.case = 'three files linked, first link will be broken';
  provider.filesDelete({ filePath : testRoutineDir, throwing : 0 });
  var paths = [ 'a', 'b', 'c' ];
  paths.forEach( ( p, i ) =>
  {
    paths[ i ] = _.path.join( testRoutineDir, p );
    provider.fileWrite( paths[ i ], 'abc' );
  });
  provider.linkHard({ dstPath : paths });
  test.is( provider.filesAreHardLinked.apply( provider,paths ) );
  provider.archive.restoreLinksBegin();
  provider.fileTouch({ filePath : paths[ 0 ], purging : 1 });
  waitSync( test.context.delay );
  test.is( provider.filesAreHardLinked( paths[ 1 ],paths[ 2 ] ) );
  test.is( !provider.filesAreHardLinked( paths[ 1 ],paths[ 0 ] ) );
  test.identical( provider.filesAreHardLinked( paths ), false );
  provider.archive.restoreLinksEnd();
  test.is( provider.filesAreHardLinked( paths[ 1 ],paths[ 2 ] ) );
  test.is( provider.filesAreHardLinked( paths[ 1 ],paths[ 0 ] ) );
  test.identical( provider.filesAreHardLinked( paths ), true );
  test.identical( provider.fileRead( paths[0] ), 'abc' );

  //

  test.case = 'three files linked, 0 link will be broken, content 0 changed';
  provider.filesDelete({ filePath : testRoutineDir, throwing : 0 });
  var paths = [ 'a', 'b', 'c' ];
  paths.forEach( ( p, i ) =>
  {
    paths[ i ] = _.path.join( testRoutineDir, p );
    provider.fileWrite( paths[ i ], 'abc' );
  });
  provider.linkHard({ dstPath : paths });
  test.is( provider.filesAreHardLinked.apply( provider,paths ) );
  provider.archive.restoreLinksBegin();
  test.identical( provider.filesAreHardLinked( paths ), true );
  provider.archive.restoreLinksEnd();
  test.identical( provider.filesAreHardLinked( paths ), true );
  test.is( provider.filesAreHardLinked( paths[ 0 ],paths[ 1 ] ) );
  test.is( provider.filesAreHardLinked( paths[ 1 ],paths[ 2 ] ) );
  test.identical( provider.fileRead( paths[0] ), 'abc' );

  //

  test.case = 'three files linked, 1 link will be broken, content 1 changed';
  provider.filesDelete( testRoutineDir );
  var paths = [ 'a', 'b', 'c' ];
  paths.forEach( ( p, i ) =>
  {
    paths[ i ] = _.path.join( testRoutineDir, p );
    provider.fileWrite( paths[ i ], 'abc' );
  });
  provider.linkHard({ dstPath : paths });
  test.is( provider.filesAreHardLinked.apply( provider,paths ) );
  provider.archive.restoreLinksBegin();
  provider.fileTouch({ filePath : paths[ 0 ], purging : 1 });
  waitSync( test.context.delay );
  provider.fileWrite( paths[ 1 ], 'bcd' );
  test.is( provider.filesAreHardLinked( paths[ 1 ],paths[ 2 ] ) );
  test.is( !provider.filesAreHardLinked( paths[ 1 ],paths[ 0 ] ) );
  test.identical( provider.filesAreHardLinked( paths ), false );
  provider.archive.restoreLinksEnd();
  test.identical( provider.filesAreHardLinked( paths ), true );
  test.is( provider.filesAreHardLinked( paths[ 0 ],paths[ 1 ] ) );
  test.is( provider.filesAreHardLinked( paths[ 1 ],paths[ 2 ] ) );
  test.identical( provider.fileRead( paths[ 0 ] ), 'bcd' );

  //

  test.case = 'three files linked, 0 link will be broken, content 2 changed';
  provider.filesDelete({ filePath : testRoutineDir, throwing : 0 });
  var paths = [ 'a', 'b', 'c' ];
  paths.forEach( ( p, i ) =>
  {
    paths[ i ] = _.path.join( testRoutineDir, p );
    provider.fileWrite( paths[ i ], 'abc' );
  });
  provider.linkHard({ dstPath : paths });
  test.is( provider.filesAreHardLinked.apply( provider,paths ) );
  provider.archive.restoreLinksBegin();
  provider.fileTouch({ filePath : paths[ 0 ], purging : 1 });
  waitSync( test.context.delay );
  provider.fileWrite( paths[ 2 ], 'bcd' );
  test.is( provider.filesAreHardLinked( paths[ 1 ],paths[ 2 ] ) );
  test.is( !provider.filesAreHardLinked( paths[ 1 ],paths[ 0 ] ) );
  test.identical( provider.filesAreHardLinked( paths ), false );
  provider.archive.restoreLinksEnd();
  test.identical( provider.filesAreHardLinked( paths ), true );
  test.is( provider.filesAreHardLinked( paths[ 0 ],paths[ 1 ] ) );
  test.is( provider.filesAreHardLinked( paths[ 1 ],paths[ 2 ] ) );
  test.identical( provider.fileRead( paths[0] ), 'bcd' );

  //

  test.case = 'three files linked, 2 link will be broken, content 0 changed';
  provider.filesDelete({ filePath : testRoutineDir, throwing : 0 });
  var paths = [ 'a', 'b', 'c' ];
  paths.forEach( ( p, i ) =>
  {
    paths[ i ] = _.path.join( testRoutineDir, p );
    provider.fileWrite( paths[ i ], 'abc' );
  });
  provider.linkHard({ dstPath : paths });
  test.is( provider.filesAreHardLinked.apply( provider,paths ) );
  provider.archive.restoreLinksBegin();
  provider.fileTouch({ filePath : paths[ 2 ], purging : 1 });
  waitSync( test.context.delay );
  provider.fileWrite( paths[ 0 ], 'bcd' );
  test.is( !provider.filesAreHardLinked( paths[ 1 ],paths[ 2 ] ) );
  test.is( provider.filesAreHardLinked( paths[ 1 ],paths[ 0 ] ) );
  test.identical( provider.filesAreHardLinked( paths ), false );
  provider.archive.restoreLinksEnd();
  test.identical( provider.filesAreHardLinked( paths ), true );
  test.is( provider.filesAreHardLinked( paths[ 0 ],paths[ 1 ] ) );
  test.is( provider.filesAreHardLinked( paths[ 1 ],paths[ 2 ] ) );
  test.identical( provider.fileRead( paths[0] ), 'bcd' );

  //

  test.case = 'three files linked, 2 link will be broken, content 1 changed';
  provider.filesDelete({ filePath : testRoutineDir, throwing : 0 });
  var paths = [ 'a', 'b', 'c' ];
  paths.forEach( ( p, i ) =>
  {
    paths[ i ] = _.path.join( testRoutineDir, p );
    provider.fileWrite( paths[ i ], 'abc' );
  });
  provider.linkHard({ dstPath : paths });
  test.is( provider.filesAreHardLinked.apply( provider,paths ) );
  provider.archive.restoreLinksBegin();
  provider.fileTouch({ filePath : paths[ 2 ], purging : 1 });
  waitSync( test.context.delay );
  provider.fileWrite( paths[ 1 ], 'bcd' );
  test.is( !provider.filesAreHardLinked( paths[ 1 ],paths[ 2 ] ) );
  test.is( provider.filesAreHardLinked( paths[ 1 ],paths[ 0 ] ) );
  test.identical( provider.filesAreHardLinked( paths ), false );
  provider.archive.restoreLinksEnd();
  test.identical( provider.filesAreHardLinked( paths ), true );
  test.is( provider.filesAreHardLinked( paths[ 0 ],paths[ 1 ] ) );
  test.is( provider.filesAreHardLinked( paths[ 1 ],paths[ 2 ] ) );
  test.identical( provider.fileRead( paths[0] ), 'bcd' );

  //

  test.case = 'three files linked, 2 link will be broken, content 2 changed';
  provider.filesDelete({ filePath : testRoutineDir, throwing : 0 });
  var paths = [ 'a', 'b', 'c' ];
  paths.forEach( ( p, i ) =>
  {
    paths[ i ] = _.path.join( testRoutineDir, p );
    provider.fileWrite( paths[ i ], 'abc' );
  });
  provider.linkHard({ dstPath : paths });
  test.is( provider.filesAreHardLinked.apply( provider,paths ) );
  provider.archive.restoreLinksBegin();
  provider.fileTouch({ filePath : paths[ 2 ], purging : 1 });
  waitSync( test.context.delay );
  provider.fileWrite( paths[ 2 ], 'bcd' );
  test.is( !provider.filesAreHardLinked( paths[ 1 ],paths[ 2 ] ) );
  test.is( provider.filesAreHardLinked( paths[ 1 ],paths[ 0 ] ) );
  test.identical( provider.filesAreHardLinked( paths ), false );
  provider.archive.restoreLinksEnd();
  test.identical( provider.filesAreHardLinked( paths ), true );
  test.is( provider.filesAreHardLinked( paths[ 0 ],paths[ 1 ] ) );
  test.is( provider.filesAreHardLinked( paths[ 1 ],paths[ 2 ] ) );
  test.identical( provider.fileRead( paths[0] ), 'bcd' );

  //

  test.case = 'three files linked, all links will be broken';
  provider.filesDelete( testRoutineDir );
  var paths = [ 'a', 'b', 'c' ];
  paths.forEach( ( p, i ) =>
  {
    paths[ i ] = _.path.join( testRoutineDir, p );
    provider.fileWrite( paths[ i ], 'abc' );
  });
  provider.linkHard({ dstPath : paths });
  provider.archive.restoreLinksBegin();
  paths.forEach( ( p, i ) =>
  {
    provider.fileTouch({ filePath : p, purging : 1 });
    waitSync( test.context.delay );
    provider.fileWrite( p, '' + i );
  })
  test.identical( provider.fileRead( paths[ 0 ] ), '0' );
  test.identical( provider.fileRead( paths[ 1 ] ), '1' );
  test.identical( provider.fileRead( paths[ 2 ] ), '2' );
  test.identical( provider.filesAreHardLinked( paths ), false );
  provider.archive.restoreLinksEnd();
  test.identical( provider.filesAreHardLinked( paths ), true );
  test.is( provider.filesAreHardLinked( paths[ 0 ],paths[ 1 ] ) );
  test.is( provider.filesAreHardLinked( paths[ 1 ],paths[ 2 ] ) );
  test.identical( provider.fileRead( paths[ 0 ] ), '2' );
  test.identical( provider.fileRead( paths[ 1 ] ), '2' );
  test.identical( provider.fileRead( paths[ 2 ] ), '2' );

  //

  test.case = 'three files linked, size of first is changed after breaking the link, write 1 last'
  var paths = [ 'a', 'b', 'c' ];
  provider.filesDelete( testRoutineDir );
  paths.forEach( ( p, i ) =>
  {
    paths[ i ] = _.path.join( testRoutineDir, p );
    provider.fileWrite( paths[ i ], 'abc' );
  });
  provider.linkHard({ dstPath : paths });
  provider.archive.restoreLinksBegin();
  provider.fileTouch({ filePath : paths[ 0 ], purging : 1 });
  waitSync( test.context.delay );
  provider.fileWrite( paths[ 0 ], 'abcd0' );
  waitSync( test.context.delay );
  provider.fileWrite( paths[ 1 ], 'abcd1' );
  test.identical( provider.filesAreHardLinked( paths ), false );
  provider.archive.restoreLinksEnd();
  test.is( provider.filesAreHardLinked( paths[ 0 ],paths[ 1 ] ) );
  test.is( provider.filesAreHardLinked( paths[ 1 ],paths[ 2 ] ) );
  test.identical( provider.fileRead( paths[ 0 ] ), 'abcd1' );
  test.identical( provider.fileRead( paths[ 1 ] ), 'abcd1' );
  test.identical( provider.fileRead( paths[ 2 ] ), 'abcd1' );

  //

  test.case = 'three files linked, size of first is changed after breaking the link, write 0 last'
  var paths = [ 'a', 'b', 'c' ];
  provider.filesDelete( testRoutineDir );
  paths.forEach( ( p, i ) =>
  {
    paths[ i ] = _.path.join( testRoutineDir, p );
    provider.fileWrite( paths[ i ], 'abc' );
  });
  provider.linkHard({ dstPath : paths });
  provider.archive.restoreLinksBegin();
  provider.fileTouch({ filePath : paths[ 0 ], purging : 1 });
  waitSync( test.context.delay );
  provider.fileWrite( paths[ 1 ], 'abcd1' );
  waitSync( test.context.delay );
  provider.fileWrite( paths[ 0 ], 'abcd0' );
  test.identical( provider.filesAreHardLinked( paths ), false );
  provider.archive.restoreLinksEnd();
  test.is( provider.filesAreHardLinked( paths[ 0 ],paths[ 1 ] ) );
  test.is( provider.filesAreHardLinked( paths[ 1 ],paths[ 2 ] ) );
  test.identical( provider.fileRead( paths[ 0 ] ), 'abcd0' );
  test.identical( provider.fileRead( paths[ 1 ] ), 'abcd0' );
  test.identical( provider.fileRead( paths[ 2 ] ), 'abcd0' );

  //

  test.case = 'three files linked, fourth is linked with the third file';
  provider.filesDelete( testRoutineDir );
  var paths = [ 'a', 'b', 'c' ];
  paths.forEach( ( p, i ) =>
  {
    paths[ i ] = _.path.join( testRoutineDir, p );
    provider.fileWrite( paths[ i ], 'abc' );
  });
  provider.linkHard({ dstPath : paths });

  /* linking fourth with second and saving info */

  paths[ 3 ] = _.path.join( testRoutineDir, 'e' );
  provider.linkHard( paths[ 3 ], paths[ 2 ] );
  provider.archive.restoreLinksBegin();

  /*  breaking linkage and changing it content */

  provider.fileWrite({ filePath : paths[ 0 ], purging : 1, data : 'bcd' });
  waitSync( test.context.delay );

  /*  checking if linkage is broken  */

  test.identical( provider.filesAreHardLinked( paths ), false );
  test.identical( provider.filesAreHardLinked( paths[ 0 ],paths[ 1 ] ), false );
  test.identical( provider.filesAreHardLinked( paths[ 1 ],paths[ 2 ] ), true );
  test.identical( provider.filesAreHardLinked( paths[ 2 ],paths[ 3 ] ), true );
  test.is( provider.fileRead( paths[ 0 ] ) !== provider.fileRead( paths[ 3 ] ) );
  test.identical( provider.fileRead( paths[ 2 ] ), provider.fileRead( paths[ 3 ] ) );

  /*  restoring linkage  */

  provider.archive.restoreLinksEnd();
  test.identical( provider.filesAreHardLinked( paths ), true );

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
  });
  provider.linkHard({ dstPath : paths });
  provider.archive.restoreLinksBegin();
  provider.fileTouch({ filePath : paths[ 0 ], purging : 1 });
  waitSync( test.context.delay );
  /* changing size of a file */
  provider.fileWrite( paths[ 0 ], 'abcd' );
  provider.archive.restoreLinksEnd();
  /* checking if link was recovered by comparing content of a files */
  test.identical( provider.filesAreHardLinked( paths ), true );

  //

  test.case = 'three files linked, changing content of a file, but saving size';
  var paths = [ 'a', 'b', 'c' ];
  provider.filesDelete( testRoutineDir );
  paths.forEach( ( p, i ) =>
  {
    paths[ i ] = _.path.join( testRoutineDir, p );
    provider.fileWrite( paths[ i ], 'abc' );
  });
  provider.linkHard({ dstPath : paths });
  provider.archive.restoreLinksBegin();
  provider.fileTouch({ filePath : paths[ 0 ], purging : 1 });
  waitSync( test.context.delay );
  /* changing size of a file */
  provider.fileWrite( paths[ 0 ], 'cad' );
  provider.archive.restoreLinksEnd();
  /* checking if link was recovered by comparing content of a files */
  test.identical( provider.filesAreHardLinked( paths ), true );

  _.fileProvider.fieldReset( 'safe', 0 );

}

restoreLinks.timeOut = 30000;

//

function restoreLinksComplex( test )
{

  var testRoutineDir = _.path.join( this.testRootDirectory, test.name );
  _.fileProvider.fieldSet( 'safe', 0 );

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

  //

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
    });

    return files;
  }

  //

  function run()
  {

    test.case = 'complex case, no content changing';
    var files = begin();

    /* make links and save info in archive */

    provider.linkHard({ dstPath : _.mapKeys( files ).slice( 0, 3 ), verbosity : 3 });
    provider.linkHard({ dstPath : _.mapKeys( files ).slice( 3, 6 ), verbosity : 3 });
    test.is( provider.filesAreHardLinked( _.mapKeys( files ).slice( 0, 3 ) ) );
    test.is( provider.filesAreHardLinked( _.mapKeys( files ).slice( 3, 6 ) ) );
    test.is( !provider.filesAreHardLinked( _.mapKeys( files ).slice( 0, 6 ) ) );
    test.is( !provider.filesAreHardLinked( _.mapKeys( files ).slice( 6, 8 ) ) );


    provider.archive.restoreLinksBegin();

    /* remove some links and check if they are broken */

    waitSync( test.context.delay )
    provider.fileWrite({ filePath : _.mapKeys( files )[ 0 ], purging : 1, data : 'a' });
    waitSync( test.context.delay )
    provider.fileWrite({ filePath : _.mapKeys( files )[ 3 ], purging : 1, data : 'b' });
    waitSync( test.context.delay )
    provider.fileWrite({ filePath : _.mapKeys( files )[ 6 ], purging : 0, data : 'd' });
    test.is( !provider.filesAreHardLinked( _.mapKeys( files ).slice( 0, 3 ) ) );
    test.is( !provider.filesAreHardLinked( _.mapKeys( files ).slice( 3, 8 ) ) );
    test.identical( provider.fileRead( _.mapKeys( files )[ 0 ] ), 'a' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 1 ] ), '3' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 2 ] ), '3' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 3 ] ), 'b' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 4 ] ), '5' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 5 ] ), '5' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 6 ] ), 'd' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 7 ] ), '8' );

    /* restore links and check if they works now */

    var records1 = provider.fileRecordContext().fileRecords( _.mapKeys( files ).slice( 0, 3 ) );
    var records2 = provider.fileRecordContext().fileRecords( _.mapKeys( files ).slice( 3, 6 ) );

    logger.log( _.entitySelect( records1, '*.stat.mtime' ).map( ( t ) => t.getTime() ) )
    logger.log( _.entitySelect( records2, '*.stat.mtime' ).map( ( t ) => t.getTime() ) )

    provider.archive.restoreLinksEnd();

    test.identical( provider.archive.verbosity, 0 );
    test.identical( provider.archive.replacingByNewest, 1 );
    test.identical( provider.archive.fileMapAutosaving, 0 );
    test.identical( provider.archive.storageFileName, '.warchive' );
    // test.identical( provider.archive.dependencyMap, {} );
    test.identical( provider.archive.fileByHashMap, {} );
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

    test.is( provider.filesAreHardLinked( _.mapKeys( files ).slice( 0, 3 ) ) );
    test.is( provider.filesAreHardLinked( _.mapKeys( files ).slice( 3, 6 ) ) );
    test.is( !provider.filesAreHardLinked( _.mapKeys( files ).slice( 0, 6 ) ) );
    test.is( !provider.filesAreHardLinked( _.mapKeys( files ).slice( 6, 8 ) ) );
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

    provider.linkHard({ dstPath : _.mapKeys( files ).slice( 0, 3 ), verbosity : 3 });
    provider.linkHard({ dstPath : _.mapKeys( files ).slice( 3, 6 ), verbosity : 3 });
    test.is( provider.filesAreHardLinked( _.mapKeys( files ).slice( 0, 3 ) ) );
    test.is( provider.filesAreHardLinked( _.mapKeys( files ).slice( 3, 6 ) ) );
    test.is( !provider.filesAreHardLinked( _.mapKeys( files ).slice( 0, 6 ) ) );
    test.is( !provider.filesAreHardLinked( _.mapKeys( files ).slice( 6, 8 ) ) );

    provider.archive.restoreLinksBegin();

    /* remove some links and check if they are broken */

    waitSync( test.context.delay )
    provider.fileWrite({ filePath : _.mapKeys( files )[ 0 ], purging : 1, data : 'a1' });
    waitSync( test.context.delay )
    provider.fileWrite({ filePath : _.mapKeys( files )[ 1 ], purging : 1, data : 'a2' });
    test.is( !provider.filesAreHardLinked( _.mapKeys( files ).slice( 0, 3 ) ) );
    test.is( !provider.filesAreHardLinked( _.mapKeys( files ).slice( 3, 8 ) ) );
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
    test.identical( provider.archive.fileByHashMap, {} );
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

    test.is( provider.filesAreHardLinked( _.mapKeys( files ).slice( 0, 3 ) ) );
    test.is( provider.filesAreHardLinked( _.mapKeys( files ).slice( 3, 6 ) ) );
    test.is( !provider.filesAreHardLinked( _.mapKeys( files ).slice( 0, 6 ) ) );
    test.is( !provider.filesAreHardLinked( _.mapKeys( files ).slice( 6, 8 ) ) );
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

    provider.linkHard({ dstPath : _.mapKeys( files ).slice( 0, 3 ), verbosity : 3 });
    provider.linkHard({ dstPath : _.mapKeys( files ).slice( 3, 6 ), verbosity : 3 });
    test.is( provider.filesAreHardLinked( _.mapKeys( files ).slice( 0, 3 ) ) );
    test.is( provider.filesAreHardLinked( _.mapKeys( files ).slice( 3, 6 ) ) );
    test.is( !provider.filesAreHardLinked( _.mapKeys( files ).slice( 0, 6 ) ) );
    test.is( !provider.filesAreHardLinked( _.mapKeys( files ).slice( 6, 8 ) ) );

    provider.archive.restoreLinksBegin();

    /* remove some links and check if they are broken */

    provider.fileWrite({ filePath : _.mapKeys( files )[ 0 ], purging : 1, data : 'a' });
    waitSync( test.context.delay );
    provider.fileWrite({ filePath : _.mapKeys( files )[ 3 ], purging : 1, data : 'b' });
    waitSync( test.context.delay );
    provider.fileWrite({ filePath : _.mapKeys( files )[ 4 ], purging : 0, data : 'c' });
    waitSync( test.context.delay );
    provider.fileWrite({ filePath : _.mapKeys( files )[ 6 ], purging : 0, data : 'd' });

    test.is( !provider.filesAreHardLinked( _.mapKeys( files ).slice( 0, 3 ) ) );
    test.is( !provider.filesAreHardLinked( _.mapKeys( files ).slice( 3, 8 ) ) );
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
    test.identical( provider.archive.fileByHashMap, {} );
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

    test.is( provider.filesAreHardLinked( _.mapKeys( files ).slice( 0, 3 ) ) );
    test.is( provider.filesAreHardLinked( _.mapKeys( files ).slice( 3, 6 ) ) );
    test.is( !provider.filesAreHardLinked( _.mapKeys( files ).slice( 0, 6 ) ) );
    test.is( !provider.filesAreHardLinked( _.mapKeys( files ).slice( 6, 8 ) ) );
    test.identical( provider.fileRead( _.mapKeys( files )[ 0 ] ), 'a' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 1 ] ), 'a' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 2 ] ), 'a' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 3 ] ), 'c' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 4 ] ), 'c' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 5 ] ), 'c' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 6 ] ), 'd' );
    test.identical( provider.fileRead( _.mapKeys( files )[ 7 ] ), '8' );

  }


  _.fileProvider.fieldReset( 'safe', 0 );
}

restoreLinksComplex.timeOut = 120000;

//

function filesLinkSame( test )
{
  var context = this;
  var dir = _.path.join( context.testRootDirectory, test.name );
  _.fileProvider.fieldSet( 'safe', 0 );
  var provider;

  function begin()
  {

    test.case = 'prepare';

    _.fileProvider.filesDeleteForce( context.testRootDirectory );

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

    _.FileProvider.Extract.readToProvider
    ({
      filesTree : filesTree,
      dstProvider : provider,
      dstPath : dir,
    });

    test.is( !!provider.fileStat( _.path.join( dir,'a' ) ) );
    test.is( !!provider.fileStat( _.path.join( dir,'dir/a' ) ) );

  }

  begin();

  test.case = 'consideringFileName : 0';

  provider.archive.filesUpdate();
  provider.archive.filesLinkSame({ consideringFileName : 0 });

  test.is( !!provider.fileStat( _.path.join( dir,'a' ) ) );
  test.is( !!provider.fileStat( _.path.join( dir,'dir/a' ) ) );

  test.is( !provider.filesAreHardLinked( _.path.join( dir,'a' ),_.path.join( dir,'b' ) ) );
  test.is( !provider.filesAreHardLinked( _.path.join( dir,'a' ),_.path.join( dir,'dir/x' ) ) );

  test.is( provider.filesAreHardLinked( _.path.join( dir,'a' ),_.path.join( dir,'c' ),_.path.join( dir,'dir/a' ) ) );
  test.is( provider.filesAreHardLinked( _.path.join( dir,'b' ),_.path.join( dir,'dir/x' ) ) );

  provider.finit();
  provider.archive.finit();

  begin();

  test.case = 'consideringFileName : 1';

  provider.archive.filesUpdate();
  provider.archive.filesLinkSame({ consideringFileName : 1 });

  test.is( !!provider.fileStat( _.path.join( dir,'a' ) ) );
  test.is( !!provider.fileStat( _.path.join( dir,'dir/a' ) ) );

  test.is( !provider.filesAreHardLinked( _.path.join( dir,'a' ),_.path.join( dir,'b' ) ) );
  test.is( !provider.filesAreHardLinked( _.path.join( dir,'a' ),_.path.join( dir,'dir/x' ) ) );

  test.is( provider.filesAreHardLinked( _.path.join( dir,'a' ),_.path.join( dir,'dir/a' ) ) );
  test.is( !provider.filesAreHardLinked( _.path.join( dir,'a' ),_.path.join( dir,'c' ) ) );
  test.is( !provider.filesAreHardLinked( _.path.join( dir,'b' ),_.path.join( dir,'dir/x' ) ) );

  provider.finit();
  provider.archive.finit();

  _.fileProvider.fieldReset( 'safe', 0 );
}

//

function severalPaths( test )
{
  var context = this;
  var dir = _.path.join( context.testRootDirectory, test.name );
  _.fileProvider.fieldSet( 'safe', 0 );
  var provider;

  function begin()
  {

    test.case = 'prepare';

    _.fileProvider.filesDeleteForce( context.testRootDirectory );

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
    provider.archive.basePath = [ _.path.join( dir,'dir1' ), _.path.join( dir,'dir2' ), _.path.join( dir,'dir3' ) ];
    provider.archive.fileMapAutosaving = 0;

    _.FileProvider.Extract.readToProvider
    ({
      filesTree : filesTree,
      dstProvider : provider,
      dstPath : dir,
    });

    test.is( !!provider.fileStat( _.path.join( dir, 'dir1/a' ) ) );
    test.is( !!provider.fileStat( _.path.join( dir, 'dir2/a' ) ) );
    test.is( !!provider.fileStat( _.path.join( dir, 'dir3/x' ) ) );

  }

  begin();

  test.case = 'consideringFileName : 1';

  provider.archive.filesUpdate();
  provider.archive.filesLinkSame({ consideringFileName : 1 });

  test.is( !!provider.fileStat( _.path.join( dir,'dir1/a' ) ) );
  test.is( !!provider.fileStat( _.path.join( dir,'dir2/a' ) ) );
  test.is( !!provider.fileStat( _.path.join( dir,'dir3/x' ) ) );

  debugger;
  test.is( provider.filesAreHardLinked( _.path.join( dir,'dir1/a' ),_.path.join( dir,'dir2/a' ) ) );
  test.is( provider.filesAreHardLinked( _.path.join( dir,'dir2/x' ),_.path.join( dir,'dir3/x' ) ) );
  debugger;

  test.is( !provider.filesAreHardLinked( _.path.join( dir,'dir1/a' ),_.path.join( dir,'dir1/b' ) ) );
  test.is( !provider.filesAreHardLinked( _.path.join( dir,'dir1/b' ),_.path.join( dir,'dir2/x' ) ) );

  provider.finit();
  provider.archive.finit();

  _.fileProvider.fieldReset( 'safe', 0 );
}

//

function inodeExperiment( test )
{
  let context = this;
  _.fileProvider.fieldSet( 'safe', 0 );

  if( Config.platform !== 'nodejs' )
  if( process.platform !== 'win32' )
  {
    test.identical( 1,1 );
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
  hash1 = provider.archive.fileMap[ pathsSameIno[ 0 ] ].hash2;
  hash2 = provider.archive.fileMap[ pathsSameIno[ 1 ] ].hash2;
  test.notIdentical( hash1, hash2 )

  provider.linkHard({ dstPath : pathsSameIno });
  test.is( provider.filesAreHardLinked.apply( provider, pathsSameIno ) )

  provider.archive.restoreLinksEnd();

  test.case = 'restored files should not be linked';
  test.is( !provider.filesAreHardLinked.apply( provider, pathsSameIno ) )
  test.case = 'restored files should not have same hash';
  hash1 = provider.fileHash( pathsSameIno[ 0 ] );
  hash2 = provider.fileHash( pathsSameIno[ 1 ] );
  test.notIdentical( hash1, hash2 );
  test.case = 'restored files should not be same';
  test.is( !provider.filesAreSame.apply( provider, pathsSameIno ) );

  provider.finit();
  provider.archive.finit();

  _.fileProvider.fieldReset( 'safe', 0 );

  /* */

  function begin()
  {
    let inodes = {};
    let pathsSameIno;

    _.fileProvider.filesDelete( dirname );

    for( let i = 0; i < 300; i++ )
    {
      let path = _.path.join( dirname, '' + i );
      _.fileProvider.fileWrite( path,path );
      let stat = _.fileProvider.fileStat( path );
      if( inodes[ stat.ino ] )
      {
        pathsSameIno = [ inodes[ stat.ino ], path ];
        logger.log( 'Inode duplication!' );
        logger.log( _.toStr( pathsSameIno ) );
        break;
      }

      inodes[ stat.ino ] = path;
    }
    return pathsSameIno;
  }
}

//

function tester( test )
{
  var self = this;

  var suite = test.suite;
  var tests = suite.tests;

  var runsLimit = 5;

  var tests =
  {
    restoreLinksComplex : restoreLinksComplex
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

var Self =
{

  name : 'Tools/mid/files/fileFilter/Archive',
  silencing : 1,
  // verbosity : 4,
  // importanceOfNegative : 5,
  // routine : 'restoreLinks',

  onSuiteBegin : onSuiteBegin,
  onSuiteEnd : onSuiteEnd,

  context :
  {
    testRootDirectory : null,
    delay : null
  },

  tests :
  {

    archive : archive,
    restoreLinks : restoreLinks,
    restoreLinksComplex : restoreLinksComplex,
    filesLinkSame : filesLinkSame,
    severalPaths : severalPaths,
    inodeExperiment : inodeExperiment,

    // tester : tester,

  },

};

Self = wTestSuite( Self )
if( typeof module !== 'undefined' && !module.parent )
_.Tester.test( Self.name );

})();
