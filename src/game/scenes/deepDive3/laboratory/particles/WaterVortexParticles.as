package game.scenes.deepDive3.laboratory.particles
{
	import flash.geom.Point;
	
	import engine.components.Spatial;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.GravityWell;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.EllipseZone;
	
	public class WaterVortexParticles extends Emitter2D
	{
		public function init($spatial:Spatial):void
		{
			_imageClass = new ImageClass( Dot, [2], true );
			
			super.addInitializer( _imageClass );
			
			_colorInit = new ColorInit(0x669999, 0xffffff);
			
			super.addInitializer( _colorInit );
			super.addInitializer( new Position( new EllipseZone( new Point(0,0), 300, 300 ) ));
			super.addInitializer( new Velocity( new EllipseZone( new Point(0,0), -50, -50 ) ));
			
			_lifetime = new Lifetime( 1.3, 0.5 );
			
			super.addInitializer( _lifetime );
			
			super.addAction( new Move() );
			
			_gravityWell = new GravityWell(3000, $spatial.x, $spatial.y, 300);
			
			super.addAction( _gravityWell );
			super.addAction( new Fade() );
			super.addAction( new Age() );
			super.addAction( new ScaleImage( 1.7, 0.1) );
			
			_origSpatial = $spatial;
		}
		
		public function sparkle($amount:Number = 45):void{
			super.counter = new Steady($amount);
		}
		
		private var _imageClass:ImageClass;
		private var _colorInit:ColorInit;
		private var _origSpatial:Spatial;
		private var _gravityWell:GravityWell;
		private var _lifetime:Lifetime;
		
	}
}