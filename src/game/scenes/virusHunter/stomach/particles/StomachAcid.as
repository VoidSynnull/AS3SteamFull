package game.scenes.virusHunter.stomach.particles
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class StomachAcid extends Emitter2D
	{		
		public function init(x:Number, y:Number, color:uint, width:Number):void
		{
			this.counter = new Steady(50);
			
			this.addInitializer(new ImageClass(Blob, [3], true));
			this.addInitializer(new Position(new RectangleZone(x - width/2, y - 20, x + width/2, y + 20)));
			this.addInitializer(new Velocity(new LineZone(new Point(-30, -150), new Point(30, -150))));
			this.addInitializer(new ScaleImageInit(1, 2));
			this.addInitializer(new ColorInit(color, color));
			this.addInitializer(new Lifetime(1));
			
			this.addAction(new Age());
			this.addAction(new Move());
			this.addAction(new Fade());
			this.addAction(new RandomDrift(0, 200));
			this.addAction(new Accelerate(0, 300));
		}
	}
}