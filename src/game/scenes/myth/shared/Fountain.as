package game.scenes.myth.shared
{	
	import flash.display.BitmapData;
	import flash.geom.Point;
	
	import game.util.DisplayUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.MutualGravity;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.PointZone;
	
	public class Fountain extends Emitter2D
	{
		public function Fountain()
		{
		}
		
		public function init( bitmapData:BitmapData, particalNum:int, angle:Number, startSpeed:Number, accelleration:Number ):void
		{
			counter = new Steady( particalNum );
			
			// when using a BitmapRender you use SharedImage or SharedImages, since each particle is being draw to bitmap it only needs to be rendered once.
			addInitializer( new BitmapImage( bitmapData, true, 2 * particalNum ));
			
			addInitializer( new Lifetime( 1 ));
			addInitializer( new ColorInit( 0x41B6E1, 0x4DCBDE ));
			
			var pt:Point = new Point();
			angle = angle * Math.PI / 180;
			pt.x = pt.x + startSpeed * Math.cos(angle);
			pt.y = pt.y + startSpeed * Math.sin(angle);
			
			addInitializer( new Velocity( new PointZone( pt )));
			
			addAction( new Move());
			addAction( new MutualGravity( 1, 10, 1 ));
			addAction( new RandomDrift( 50, 10 ));			
			addAction( new Fade( .75, 1 ));			
			addAction( new ScaleImage( .4, 1.5 ));	
			addAction( new Accelerate( 0, accelleration ));
			addAction( new Age());
		}
	}
}