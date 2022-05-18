package game.particles.emitter
{
	import flash.geom.Point;
	
	import game.util.DataUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.TimePeriod;
	import org.flintparticles.common.initializers.ExternalImage;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.PointZone;
	
	public class CoinEmitter extends Emitter2D
	{
		public function CoinEmitter(coins:int, target:Point, origin:Point, asset:String = null)
		{
			counter = new TimePeriod(coins,1);
			
			var url:String = DataUtils.validString(asset)? asset : "assets/particles/coinFlip.swf";
			
			
			addInitializer(new ExternalImage(url,true));
			addInitializer(new Position(new PointZone(origin)));
			addInitializer(new Velocity(new PointZone(new Point(0,target.y - origin.y))));
			addInitializer(new Lifetime(1));
			
			addAction(new Age());
			addAction(new Move());
			addAction(new Accelerate((target.x - origin.x) * 2,0));
		}
	}
}