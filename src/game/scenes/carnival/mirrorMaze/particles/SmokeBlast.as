package game.scenes.carnival.mirrorMaze.particles
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscSectorZone;
	import org.flintparticles.twoD.zones.DiscZone;
	
	public class SmokeBlast extends Emitter2D
	{	
		public function SmokeBlast() {
			
		}
		
		public function init():void
		{
			super.counter = new Blast(20);
			addInitializer(new Lifetime(0.2, 0.4));
			addInitializer(new Velocity(new DiscSectorZone(new Point(0,0), 400, 250, -Math.PI, Math.PI )));
			addInitializer(new Position(new DiscZone(new Point(0,0), 18)));
			addInitializer(new ImageClass(Blob, [28,0xffffff], true, 20));
			addAction(new Age());
			addAction(new Move());
			addAction(new RotateToDirection());
			addAction(new Fade(0.8,0.1));
		}
	}
}