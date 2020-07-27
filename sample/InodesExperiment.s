
if( typeof module !== 'undefined' )
{
  require( 'wfilesarchive' );
}

let _ = _global_.wTools;

/**/

let dirname = _.path.join( __dirname, 'tmp.tmp' );
let inodes = {};
let pathsSameIno;

for( let i = 0; i < 10; i++ )
{
  let path = _.path.join( dirname, '' + i + '.txt' );
  _.fileProvider.fileWrite( path, path );
  let stat = _.fileProvider.statRead( path );
  let index = '' + parseInt( stat.ino );
  if( i === 9 )
  i--;
  if( inodes[ index ] )
  {
    pathsSameIno = inodes[ index ] = [ inodes[ index ], path ];
    logger.log( 'Inode duplication!' );
    logger.log( _.toStr( pathsSameIno ) );
    break;
  }
  inodes[ index ] = path;
}

/**/

var provider = _.FileFilter.Archive();
provider.archive.basePath = dirname;
provider.archive.verbosity = 0;
provider.archive.fileMapAutosaving = 0;
provider.archive.comparingRelyOnHardLinks = 1;

provider.archive.restoreLinksBegin();

logger.log( 'Comparing hash2 of', _.toStr( pathsSameIno, { levels : 2 } ) );
let hash1 = provider.archive.fileMap[ pathsSameIno[ 0 ] ].hash2;
let hash2 = provider.archive.fileMap[ pathsSameIno[ 1 ] ].hash2;
logger.log( hash1, hash2 );
logger.log( 'Same:', hash1 === hash2 );

logger.log( 'Linking two files with same inode.' )
provider.hardLink( { dstPath : pathsSameIno } );
logger.log( 'Linked: ', provider.areHardLinked.apply( provider, pathsSameIno ) );

provider.archive.restoreLinksEnd();

logger.log( 'Restoring, files should be restored' )
logger.log( 'Linked: ', provider.areHardLinked.apply( provider, pathsSameIno ) );
hash1 = provider.hashRead( pathsSameIno[ 0 ] );
hash2 = provider.hashRead( pathsSameIno[ 1 ] );
logger.log( 'Comparing hash of files, should be not same' );
logger.log( hash1, hash2 );
logger.log( 'Same:', hash1 === hash2 );
