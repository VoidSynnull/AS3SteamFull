package game.particles.emitter.specialAbility
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
	
	public class HammerImpact extends Emitter2D
	{
		public function HammerImpact()
		{
			super();
		}
		public function init():void{
			this.counter = new Blast(20);
			this.addInitializer(new Lifetime(0.2, 0.4));
			this.addInitializer(new Velocity(new DiscSectorZone(new Point(0,0), 400, 250, -Math.PI, Math.PI )));
			this.addInitializer(new Position(new DiscZone(new Point(0,0), 18)));
			this.addInitializer(new ImageClass(Blob, [28,0xffffff], true, 20));
			this.addAction(new Age());
			this.addAction(new Move());
			this.addAction(new RotateToDirection());
			this.addAction(new Fade(0.8,0.1));
		}
	}
}