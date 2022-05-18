package game.particles.emitter.specialAbility
{
	import flash.geom.Point;
	
	import engine.components.Spatial;
	
	import fl.motion.easing.Quadratic;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Ellipse;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.RotationAbsolute;
	import org.flintparticles.twoD.zones.DiscZone;
	
	public class DiscTrail extends Emitter2D
	{
		public function DiscTrail()
		{
			
		}
		
		public override function update(time:Number):void
		{
			_rotationAbs.angle = _followTarget.rotation * (Math.PI/180);
			super.update(time);
		}
		
		public function init(width:Number, height:Number, color:uint, target:Spatial):void
		{
			_followTarget = target;
			_rotationAbs = new RotationAbsolute(target.rotation * (Math.PI/180));
			
			super.counter = new Steady(40);
			addInitializer(new Lifetime(.4));
			addInitializer(new Position(new DiscZone(new Point(0,0))));
			addInitializer(new ImageClass(Ellipse, [width, height, color], true));
			addInitializer(_rotationAbs);
			addInitializer(new AlphaInit(.8));
			
			addAction(new Age(Quadratic.easeOut));
			addAction(new Fade(.8, 0));
			addAction(new Move());
		}
		
		private var _rotationAbs:RotationAbsolute;
		private var _followTarget:Spatial;
	}
}