/*
 * Author: Rick Hocker
 */

package org.flintparticles.common.initializers
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	import engine.group.Group;
	import flash.geom.Matrix;

	/**
	 * The ImageClass Initializer sets the DisplayObject to use to draw
	 * the particle. It is used with the DisplayObjectRenderer. When using the
	 * BitmapRenderer it is more efficient to use the SharedImage Initializer.
	 * 
	 * <p>This class includes an object pool for reusing DisplayObjects when particles die.</p>
	 * 
	 * <p>To enable use of the object pool, it was necessary to alter the constructor so the 
	 * parameters for the image class are passed as an array rather than as plain values.</p>
	 */
	public class ExternalSwfImage extends ImageInitializerBase
	{
		private var _swf:MovieClip;
		private var _group:Group;
		
		/**
		 * The constructor creates an ExternalImage initializer for use by 
		 * an emitter. To add an ExternalImage to all particles created by an emitter, use the
		 * emitter's addInitializer method.
		 * 
		 * @param assetPath path to the asset that will be used as the particle display.
		 * @param usePool Indicates whether particles should be reused when a particle dies.
		 * @param fillPool Indicates how many particles to create immediately in the pool, to
		 * avoid creating them when the particle effect is running.
		 * 
		 * @see org.flintparticles.common.emitters.Emitter#addInitializer()
		 */
		public function ExternalSwfImage( swf:MovieClip, usePool:Boolean = false, fillPool:uint = 0 )
		{
			super( usePool );
			_swf = swf;
			if( fillPool > 0 )
			{
				this.fillPool( fillPool );
			}
		}
		
		/**
		 * The class to use when creating
		 * the particles' DisplayObjects.
		 */
		public function get swf():MovieClip
		{
			return _swf;
		}
		public function set swf( clip:MovieClip ):void
		{
			_swf = clip;
			if( _usePool )
			{
				clearPool();
			}
		}
		
		/**
		 * Used internally, this method creates an image object for displaying the particle 
		 * by calling the image class constructor with the supplied parameters.
		 * The supplied image is assigned to the Particle class's image variable.
		 */
		override public function createImage() : Object
		{
			var sprite:Sprite = new Sprite();
			sprite.mouseChildren = false;
			sprite.mouseEnabled = false;
			if (_swf != null)
			{
				// get random frame
				if (_swf.totalFrames != 1)
					_swf.gotoAndStop(1 + Math.floor(Math.random() * _swf.totalFrames));
				var bd:BitmapData = new BitmapData( _swf.width, _swf.height, true, 0x00000000 );
				var matrix:Matrix = new Matrix();
				// assumes swf is centered
				matrix.translate(_swf.width/2, _swf.height/2);
				bd.draw(_swf, matrix);
				var bitmap:Bitmap = new Bitmap(bd);
				sprite.addChild(bitmap);
				bitmap.x = -_swf.width/2;
				bitmap.y = -_swf.height/2;
			}
			return sprite;
		}
	}
}
