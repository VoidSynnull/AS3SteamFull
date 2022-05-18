package game.scenes.ftue.shared.particles
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Confetti;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ChooseInitializer;
	import org.flintparticles.common.initializers.ColorsInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.CircularAcceleration;
	import org.flintparticles.twoD.actions.LinearDrag;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscSectorZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class ConfettiScene extends Emitter2D
	{
		private const DEFAULT_COLORS:Array = [0xFF3E3E, 0xFF9900, 0xFBF404, 0x66FF00,0x0D91F2,0xA476D1,0xEF0065];
		
		public function ConfettiScene()
		{
			super();
		}
		
		public function init(width:Number, color1:uint = 0xFFFBAF, color2:uint = 0xCFB776, counterNum:uint = 30):void
		{
			this.addInitializer(new ChooseInitializer([new ImageClass(Confetti, [8, color1], true), new ImageClass(Confetti, [10, color2], true)]));
			this.addInitializer(new ScaleImageInit(.5, 1.5));
			this.addInitializer(new Lifetime(20, 20));
			this.addInitializer(new Velocity(new DiscSectorZone(new Point(0, 0), 200, 0, -Math.PI, 0)));
			this.addInitializer(new Position(new RectangleZone(0,0, width, 10)));
			this.addInitializer(new ColorsInit(DEFAULT_COLORS));
			this.addInitializer(new AlphaInit(1));
			
			this.addAction(new Accelerate(0, 400));
			this.addAction(new Age());
			this.addAction(new Move());
			this.addAction(new RotateToDirection());
			this.addAction(new LinearDrag(2));
			this.addAction(new CircularAcceleration(100, 3));
			this.addAction(new RandomDrift(500));
		}
		
		public function stream():void{
			super.counter = new Steady(30);
		}
	}
}