/*

* Author: Bard McKinley
*/

package org.flintparticles.common.initializers
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	
	import engine.ShellApi;
	import engine.util.Command;
	
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
	public class ExternalImage extends ImageInitializerBase
	{
		private var _assetPath:String;
		
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
		public function ExternalImage(assetPath:String, usePool:Boolean = false, fillPool:uint = 0 )
		{
			super( usePool );
			_assetPath = assetPath;
			if( fillPool > 0 )
			{
				this.fillPool( fillPool );
			}
		}
		
		/**
		 * The parameters to pass to the constructor
		 * for the image class.
		 */
		public function get assetPath():String
		{
			return _assetPath;
		}
		public function set assetPath( assetPath:String ):void
		{
			_assetPath = assetPath;
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
			//changing the method of loading to our inhouse loading system
			var sprite:Sprite = new Sprite();
			ShellApi.SHELL_API.fileManager.loadFile(_assetPath,Command.create(assetLoadded, sprite));
			return sprite;
		}
		
		private function assetLoadded(asset:DisplayObjectContainer, container:DisplayObjectContainer):void
		{
			container.addChild(asset);
		}
	}
}