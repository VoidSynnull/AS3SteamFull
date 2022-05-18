/**
 * ...
 * @author Scott
 */

package game.scenes.time.shared.emitters 
{
	
	import flash.display.DisplayObject;
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Line;
	import org.flintparticles.common.easing.Quadratic;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.activities.FollowDisplayObject;
	import org.flintparticles.twoD.activities.MoveEmitter;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.PointZone;
	
	public class WispySmoke extends Emitter2D
	{
		
		private var posShift:Number = 0;
		private var forward:Boolean = true;
		
		public function WispySmoke() 
		{
			
		}
		
		override public function update(time:Number):void
		{
			if(posShift > 101){
				forward = false
			}
			else if(posShift <-101)
			{
				forward = true;
			}
			if(forward){
				addInitializer(new Position(new PointZone(new Point(563 + posShift, 758))));
				posShift++;
			}
			else
			{
				addInitializer(new Position(new PointZone(new Point(563 + posShift, 758))));
				posShift--;
			}
			super.update(time);
		}
		
		public function init(rate:Number):void
		{
			counter = new Steady(rate);
			
			addInitializer(new ImageClass(Line, [5, 0xffffff, "normal"], true));
			addInitializer(new Velocity(new LineZone(new Point(0, -50), new Point(0, -70))));
			addInitializer(new Position(new PointZone(new Point(563, 758))));
			addInitializer(new Lifetime(4, 4));
			addInitializer( new AlphaInit( .6, .6 ));
			
			addAction(new Fade(0.2,0.08));
			addAction(new Age(Quadratic.easeIn));
			addAction(new Move());
			addAction(new Accelerate(0, -5));
			addAction( new ScaleImage( .7, 1 ) );

		}
	}
}