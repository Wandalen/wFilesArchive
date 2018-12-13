( function _FilesGraph_test_s_( ) {

'use strict';

if( typeof module !== 'undefined' )
{

  var _ = require( '../../Tools.s' );

  _.include( 'wTesting' );
  _.include( 'wFiles' );
  _.include( 'wFilesArchive' );

  var waitSync = require( 'wait-sync' );

}

//

var _ = _global_.wTools;
var Parent = wTester;

// --
//
// --

function trivial( test )
{

  /* - */

  test.case = 'universal, linking : fileCopy';

  var expectedExtract = _.FileProvider.Extract
  ({
    filesTree :
    {
      src :
      {
        same : 'same',
        diff : 'src/diff',
        srcDirDstTerm : { f2 : 'src/srcDirDstTerm/f2', f3 : 'src/srcDirDstTerm/f3' },
        srcTermDstDir : 'src/srcTermDstDir',
        srcTerm : 'srcTerm',
        srcDir : {},
      },
      dst :
      {
        same : 'same',
        diff : 'src/diff',
        srcDirDstTerm : { f2 : 'src/srcDirDstTerm/f2', f3 : 'src/srcDirDstTerm/f3' },
        srcTermDstDir : 'src/srcTermDstDir',
        // dstTerm : 'dstTerm',
        // dstDir : {},
        srcTerm : 'srcTerm',
        srcDir : {},
      }
    },
  });

  var extract = _.FileProvider.Extract
  ({
    filesTree :
    {
      src :
      {
        same : 'same',
        diff : 'src/diff',
        srcDirDstTerm : { f2 : 'src/srcDirDstTerm/f2', f3 : 'src/srcDirDstTerm/f3' },
        srcTermDstDir : 'src/srcTermDstDir',
        srcTerm : 'srcTerm',
        srcDir : {},
      },
      dst :
      {
        same : 'same',
        diff : 'dst/diff',
        srcDirDstTerm : 'dst/srcDirDstTerm',
        srcTermDstDir : { f2 : 'src/srcDirDstTerm/f2', f3 : 'src/srcDirDstTerm/f3' },
        dstTerm : 'dstTerm',
        dstDir : {},
      }
    },
  });

  var image = _.FileFilter.Image({ originalFileProvider : extract });
  let archive = new _.FilesGraphArchive({ imageFileProvider : image });

  archive.timelapseBegin();

  image.filesDelete( '/dst' );

  debugger;
  let records = image.filesReflect
  ({
    reflectMap : { '/src' : '/dst' },
    dstRewriting : 0,
    dstRewritingByDistinct : 0,
    linking : 'fileCopy',
  });
  debugger;

  archive.timelapseEnd();

  var expAbsolutes = [ '/dst', '/dst/diff', '/dst/same', '/dst/srcTerm', '/dst/srcTermDstDir', '/dst/srcDir', '/dst/srcDirDstTerm', '/dst/srcDirDstTerm/f2', '/dst/srcDirDstTerm/f3' ];
  var expActions = [ 'dirMake', 'fileCopy', 'fileCopy', 'fileCopy', 'fileCopy', 'dirMake', 'dirMake', 'fileCopy', 'fileCopy' ];
  var expPreserve = [ false, false, false, false, false, false, false, false, false ];

  var gotAbsolutes = _.select( records, '*/dst/absolute' );
  var gotActions = _.select( records, '*/action' );
  var gotPreserve = _.select( records, '*/preserve' );

  test.identical( extract.filesTree, expectedExtract.filesTree );
  test.identical( gotAbsolutes, expAbsolutes );
  test.identical( gotActions, expActions );
  test.identical( gotPreserve, expPreserve );

}

// --
// declare
// --

var Self =
{

  name : 'Tools/mid/files/Graph',
  silencing : 1,

  context :
  {
  },

  tests :
  {

    trivial,

  },

};

Self = wTestSuite( Self )
if( typeof module !== 'undefined' && !module.parent )
wTester.test( Self.name );

})();
