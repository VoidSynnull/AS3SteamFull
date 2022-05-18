package game.scenes.deepDive3.shared.particles
{
	import flash.geom.Point;
	
	import engine.components.Spatial;
	
	import game.util.PerformanceUtils;
	
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
	
	public class MemoryParticles extends Emitter2D
	{
		public function init($spatial:Spatial):void
		{
			_imageClass = new ImageClass( Dot, [2], true );
			
			super.addInitializer( _imageClass );
			
			_colorInit = new ColorInit(0x61FF34, 0xffffff);
			
			super.addInitializer( _colorInit );
			super.addInitializer( new Position( new EllipseZone( new Point(0,0), 300, 300 ) ));
			super.addInitializer( new Velocity( new EllipseZone( new Point(0,0), -50, -50 ) ));
			
			_lifetime = new Lifetime( 4, 0.5 );
			
			super.addInitializer( _lifetime );
			
			super.addAction( new Move() );
			
			_gravityWell = new GravityWell(250, $spatial.x, $spatial.y, 150);
			
			super.addAction( _gravityWell );
			super.addAction( new Fade() );
			super.addAction( new Age() );
			super.addAction( new ScaleImage( 1.4, 0.1) );
			
			_origSpatial = $spatial;
		}
		
		public function sparkle($amount:Number = 25):void{
			super.counter = new Steady($amount);
		}
		
		public function attractToSpatial($spatial:Spatial):void{
			_gravityWell.x = $spatial.x;
			_gravityWell.y = $spatial.y;
		}
		
		public function activateMemory($amount:Number = 75):void{
			_colorInit.minColor = 0xDC609A; // change to pink
			_gravityWell.power = 3000; // increase gravity power
			_gravityWell.epsilon = 400;
			
			//_imageClass.parameters = [3]; // increase size of particles
			
			_lifetime.maxLifetime = 1;
			super.counter = new Steady($amount); // increase particle amount
		}
		
		public function deactivateMemory():void{
			_colorInit.minColor = 0x61FF34; 
			_gravityWell.power = 250; 
			_gravityWell.epsilon = 150;
			
			//_imageClass.parameters = [2]; 
			
			_lifetime.maxLifetime = 4;
			if(PerformanceUtils.qualityLevel <= PerformanceUtils.QUALITY_HIGH){
				super.counter = new Steady(5);
			} else {
				super.counter = new Steady(25);
			}
			
		}
		
		private var _imageClass:ImageClass;
		private var _colorInit:ColorInit;
		private var _origSpatial:Spatial;
		private var _gravityWell:GravityWell;
		private var _lifetime:Lifetime;
		
	}
}