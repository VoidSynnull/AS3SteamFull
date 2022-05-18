package game.scenes.deepDive3.shared.particles
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
	
	public class ModuleParticles extends Emitter2D
	{
		public function init():void
		{
			_imageClass = new ImageClass( Dot, [2], true );
			
			super.addInitializer( _imageClass );
			
			_colorInit = new ColorInit(0x61FF34, 0xffffff);
			
			super.addInitializer( _colorInit );
			super.addInitializer( new Position( new EllipseZone( new Point(0,0), 45, 45 ) ));
			super.addInitializer( new Velocity( new EllipseZone( new Point(0,0), 20, 20 ) ));
			
			_lifetime = new Lifetime( 6, 0.5 );
			
			super.addInitializer( _lifetime );
			
			super.addAction( new Move() );

			super.addAction( new Fade() );
			super.addAction( new Age() );
			super.addAction( new ScaleImage( 1.4, 0.1) );
		}
		
		public function sparkle($amount:Number = 15):void{
			super.counter = new Steady($amount);
		}
		
		private var _imageClass:ImageClass;
		private var _colorInit:ColorInit;
		private var _origSpatial:Spatial;
		private var _gravityWell:GravityWell;
		private var _lifetime:Lifetime;
		
	}
}