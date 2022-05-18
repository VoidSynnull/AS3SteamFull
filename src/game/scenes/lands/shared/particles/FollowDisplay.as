package game.scenes.lands.shared.particles {

	import flash.display.DisplayObject;
	import flash.geom.Point;
	
	import engine.components.Display;
	
	import org.flintparticles.common.activities.ActivityBase;
	import org.flintparticles.common.emitters.Emitter;
	import org.flintparticles.common.utils.DisplayObjectUtils;
	import org.flintparticles.twoD.emitters.Emitter2D;
	
	/**
	 * The FollowDisplayObject activity causes the emitter to follow
	 * the position and rotation of a DisplayObject. The purpose is for the emitter
	 * to emit particles from the location of the DisplayObject.
	 */
	public class FollowDisplay extends ActivityBase {

		private var _renderer:DisplayObject;
		private var display:Display;
		
		/**
		 * The constructor creates a FollowDisplayObject activity for use by 
		 * an emitter. To add a FollowDisplayObject to an emitter, use the
		 * emitter's addActvity method.
		 * 
		 * @param renderer The display object whose coordinate system the DisplayObject's position is 
		 * converted to. This is usually the renderer for the particle system created by the emitter.
		 * 
		 * @see org.flintparticles.common.emitters.Emitter#addActivity()
		 */
		public function FollowDisplay( followDisplay:Display = null, renderer:DisplayObject = null )
		{
			this.display = followDisplay;
			this.renderer = renderer;
		}
		
		/**
		 * The DisplayObject whose coordinate system the DisplayObject's position is converted to. This
		 * is usually the renderer for the particle system created by the emitter.
		 */
		public function get renderer():DisplayObject
		{
			return _renderer;
		}
		public function set renderer( value:DisplayObject ):void
		{
			_renderer = value;
		}

		/**
		 * @inheritDoc
		 */
		override public function update( emitter : Emitter, time : Number ) : void
		{
			var e:Emitter2D = Emitter2D( emitter );
			var p:Point = new Point( 0, 0 );
			p = this.display.displayObject.localToGlobal( p );
			p = _renderer.globalToLocal( p );

			e.x = p.x;
			e.y = p.y;

		}
	}
}
