package game.scenes.arab2.shared
{
	import flash.geom.Point;
	
	import engine.group.Group;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.easing.Quadratic;
	import org.flintparticles.common.events.EmitterEvent;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.GravityWell;
	import org.flintparticles.twoD.actions.LinearDrag;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscZone;
	
	public class SparkleBlast extends Emitter2D
	{		
		private var endFunc:Function;
		
		public function SparkleBlast()
		{
			super();
		}
		public function init(group:Group, endFunc:Function, x:Number = 0, y:Number = 0, speed:Number = 100, count:Number = 100):void
		{
			counter = new Blast( count );
			
			//addInitializer( new SharedImage( new Dot( 2 ) ) );
			addInitializer(new ImageClass(Dot, [1.6], true, 6));
			addInitializer( new ColorInit( 0xFFccff, 0xFFFFFF ) );
			addInitializer( new Velocity( new DiscZone( new Point( 0, 0 ), speed, speed*0.7 ) ) );
			addInitializer(new Position(new DiscZone(new Point(0,0), 18)));
			addInitializer( new Lifetime( 3 ) );
			
			addAction( new Age( Quadratic.easeIn ) );
			addAction( new Move() );
			addAction( new Fade(1,0) );
			addAction( new Accelerate( 0, -25 ) );
			addAction( new LinearDrag( 0.8 ) );
			addAction(new org.flintparticles.twoD.actions.GravityWell(-10));
			this.endFunc = endFunc;
			addEventListener( EmitterEvent.EMITTER_EMPTY, ending, false, 0, true );
		}
		
		private function ending(...p):void
		{
			stop()
			endFunc();
		}
		
	}
}