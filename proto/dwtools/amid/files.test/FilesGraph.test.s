( function _FilesGraph_test_s_( ) {

'use strict';

var isBrowser = true;
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

  var extract = _.FileProvider.Extract
  ({
    filesTree :
    {
      src :
      {
        f1 : '1',
        d : { f2 : '2', f3 : '3' },
      },
      dst :
      {
        f1 : 'dst',
        d : 'dst',
      }
    },
  });

  var image = _.FileFilter.Image({ original : extract });
  let archive = new _.FilesGraphArchive({ fileProvider : image });

  archive.begin();

  image.filesDelete( '/dst' );

  debugger;
  image.filesReflect
  ({
    reflectMap : { '/src' : '/dst' },
  });
  debugger;

  archive.end();

  var expected = [ '/', '/dst', '/dst/f1', '/dst/d', '/dst/d/f2', '/dst/d/f3', '/src', '/src/f1', '/src/d', '/src/d/f2', '/src/d/f3' ];
  var files = extract.filesFindRecursive({ filePath : '/', outputFormat : 'absolute' })

  test.identical( files, expected );

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
