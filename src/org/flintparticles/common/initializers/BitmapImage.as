/*
* FLINT PARTICLE SYSTEM
* .....................
* 
* Author: Richard Lord
* Copyright (c) Richard Lord 2008-2011
* http://flintparticles.org
* 
* 
* Licence Agreement
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
* 
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

/**
 * 
 * Author: Bard McKinley 
 */
package org.flintparticles.common.initializers 
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	
	import org.flintparticles.common.emitters.Emitter;
	
	/**
	 * The BitmapImage Initializer sets the DisplayObject to use to a Bitmap created from a single BitmapData.
	 * Since BitmapData clean up is necessary, the BitmapData is disposed when the Initializer is removed from the Emitter.
	 * 
	 * <p>This class includes an object pool for reusing DisplayObjects when particles die.</p>
	 * 
	 * <p>To enable use of the object pool, it was necessary to alter the constructor so the 
	 * parameters for the image class are passed as an array rather than as plain values.</p>
	 */
	public class BitmapImage extends ImageInitializerBase
	{
		private var _bitmapData:BitmapData;
		
		/**
		 * The constructor creates an ImageClass initializer for use by 
		 * an emitter. To add an ImageClass to all particles created by an emitter, use the
		 * emitter's addInitializer method.
		 * 
		 * @param imageClass The class to use when creating
		 * the particles' DisplayObjects.
		 * @param parameters The parameters to pass to the constructor
		 * for the image class.
		 * @param usePool Indicates whether particles should be reused when a particle dies.
		 * @param fillPool Indicates how many particles to create immediately in the pool, to
		 * avoid creating them when the particle effect is running.
		 * 
		 * @see org.flintparticles.common.emitters.Emitter#addInitializer()
		 */
		public function BitmapImage( bitmapData:BitmapData = null, usePool:Boolean = false, fillPool:uint = 0 )
		{
			super( usePool );
			_bitmapData = bitmapData;
			if( fillPool > 0 )
			{
				this.fillPool( fillPool );
			}
		}

		/**
		 * The class to use when creating
		 * the particles' DisplayObjects.
		 */
		public function get bitmapData():BitmapData
		{
			return _bitmapData;
		}
		public function set bitmapData( data:BitmapData ):void
		{
			_bitmapData = data;
			if( _usePool )
			{
				clearPool();
			}
		}
		
		/**
		 * When removed from an emitter, the initializer will stop listening for dead particles from that emitter.
		 */
		override public function removedFromEmitter( emitter:Emitter ) : void
		{
			_bitmapData.dispose();
			super.removedFromEmitter( emitter );
		}
		
		/**
		 * Clears the image pool, forcing all particles to be created anew.
		 */
		override public function clearPool():void
		{
			if( _pool )
			{
				var length:uint = _pool.length;
				for (var i:int = 0; i < length; i++) 
				{
					var sprite:Sprite = _pool[i];
					var bitmap:Bitmap = Bitmap(sprite.getChildAt(0));
					bitmap.bitmapData = null;
				}
			}
			_pool = new Array();
		}
		
		/**
		 * Used internally, this method creates an image object for displaying the particle 
		 * by calling the image class constructor with the supplied parameters.
		 */
		override public function createImage() : Object
		{
			var sprite:Sprite = new Sprite();
			sprite.mouseChildren = false;
			sprite.mouseEnabled = false;
			var bitmap:Bitmap = new Bitmap(_bitmapData);
			sprite.addChild(bitmap);
			bitmap.x = -bitmap.width / 2;
			bitmap.y = -bitmap.height / 2;
			return sprite;
		}
	}
}

