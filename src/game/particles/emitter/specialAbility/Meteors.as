package game.particles.emitter.specialAbility 
{
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.initializers.ExternalImage;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.DeathZone;
	import org.flintparticles.twoD.actions.LinearDrag;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscSectorZone;
	import org.flintparticles.twoD.zones.DiscZone;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.PointZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	
	public class Meteors extends Emitter2D
	{	
		private var sceneW : Number=2400;
		private var sceneH : Number=1000;
		private var sAssetPath : String = "";
		
		public function Meteors(xW:Number=2400, yH:Number=1000, sSwfPath:String="assets\scenes\testIsland\leightonsSpecialAbilities\meteorite.swf") 
		{	
			sceneW = xW;
			sceneH = yH;
			sAssetPath = sSwfPath;
		}
		
		public function init():void
		{
			var startLineZone:LineZone = new LineZone( new Point( 0, 0 ), new Point( sceneW, 0 ) );
			
			super.counter = new Steady( 14 );
			addInitializer( new ExternalImage( sAssetPath ) );
			addInitializer( new Lifetime( 2, 4 ) );
			addInitializer( new Position( startLineZone ) );
			addInitializer( new Velocity( new PointZone(new Point(-400, 900) ) ) );
			
			addAction( new Age( ) );
			addAction( new Move( ) );
			addAction( new ScaleImage( 0.2, 1.5 ) );
			addAction( new Accelerate(-20, 50));
		}
		
		public function set rate(rate:int):void
		{
			Steady(super.counter).rate = rate;
		}
	}
	

}