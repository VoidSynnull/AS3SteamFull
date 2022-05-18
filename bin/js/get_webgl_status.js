/**
 * Script to get WebGL info.
 *
 * @returns {{renderer: *, vendor: *}|{renderer: string, vendor: string}}
 * renderer and vendor are 'None' if we cannot get a WebGL canvas.
 */
function get_webgl_status() {
  var canvas = document.createElement('canvas');
  var gl;
  var debugInfo;
  var vendor;
  var renderer;

  try {
    gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
  } catch (e) {
    return {vendor: 'None', renderer: ('Exception:' + e) };
  }

  if (gl) {
    debugInfo = gl.getExtension('WEBGL_debug_renderer_info');
    vendor = gl.getParameter(debugInfo.UNMASKED_VENDOR_WEBGL);
    // Get rid of non-USASCII characters - these are rejected by brain event tracker
    vendor = vendor.replace(/[^\x20-\x7E]+/g, ' ');
    renderer = gl.getParameter(debugInfo.UNMASKED_RENDERER_WEBGL);
    renderer = renderer.replace(/[^\x20-\x7E]+/g, ' ').trim();
    if (renderer.length > 64) {
      renderer = renderer.substring(0, 61) + '...';
    }
  } else {
    vendor = 'None';
    renderer = 'WebGLNotSupported';
  }
  return {vendor: vendor, renderer: renderer};
}

// Sample output:
//
// » console.log(renderer);
// ATI Technologies Inc. AMD Radeon R9 M370X OpenGL Engine
