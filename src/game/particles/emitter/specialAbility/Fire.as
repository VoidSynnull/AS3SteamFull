package game.particles.emitter.specialAbility 
{
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Point;
	import game.particles.emitter.specialAbility.FireBlob;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.ColorChange;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.LinearDrag;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscSectorZone;
	import org.flintparticles.twoD.zones.DiscZone;
	import org.flintparticles.common.displayObjects.Blob;
	
	
	public class Fire extends Emitter2D
	{	
		
		public function Fire() 
		{	
	
		}
		
		public function init():void
		{
			super.counter = new Steady( 80 );
			addInitializer( new Lifetime( 1, 3 ) );
			addInitializer( new Velocity( new DiscSectorZone( new Point( 0, 0 ), 16, 10, -Math.PI, 0 ) ) );
			addInitializer( new Position( new DiscZone( new Point( 0, 0 ), 9 ) ) );
			addInitializer( new ImageClass( Blob, [9, 0xFFFF00], true) );
			
			addAction( new Age( ) );
			addAction( new Move( ) );
			addAction( new LinearDrag( 1 ) );
			addAction( new Accelerate( 0, -50 ) );
			addAction( new ColorChange( 0xFFFF6600, 0x00CC0000 ) );
			addAction( new ScaleImage( 0.7, 0.1 ) );
			addAction( new RotateToDirection() );
		}
		
		public function set rate(rate:int):void
		{
			Steady(super.counter).rate = rate;
		}
	}
	

}