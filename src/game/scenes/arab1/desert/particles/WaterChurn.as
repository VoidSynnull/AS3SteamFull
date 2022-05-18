package game.scenes.arab1.desert.particles
{
	import flash.geom.Point;
	
	import engine.group.Group;
	
	import game.data.TimedEvent;
	import game.util.SceneUtil;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.EllipseZone;
	
	public class WaterChurn extends Emitter2D
	{
		
		
		public function init($group:Group, $width:Number = 230):void
		{
			_group = $group;
			_imageClass = new ImageClass( Dot, [4], true );
			super.addInitializer( _imageClass );
			
			_colorInit = new ColorInit(0x50B0D6, 0xFFFFFF);
			_position = new Position( new EllipseZone( new Point(0,0), $width, 10 ) );
			_velocity = new Velocity( new EllipseZone( new Point(0,0), 10, 10 ) );
			
			super.addInitializer( _colorInit );
			super.addInitializer( _position );
			super.addInitializer( _velocity );
			
			_lifetime = new Lifetime( 2, 0.5 );
			
			super.addInitializer( _lifetime );
			
			super.addAction( new Move() );
			super.addAction( new Fade() );
			super.addAction( new Age() );
			super.addAction( new Accelerate( 0, 0) );
		}
		
		public function stream():void{
			super.counter = new Steady(40);
			flowing = true;
		}
		
		public function stopStream():void
		{
			super.counter = new Steady(0);
			flowing = false;
		}
		
		public var flowing:Boolean = false;
		
		private var _imageClass:ImageClass;
		private var _lifetime:Lifetime;
		private var _position:Position;
		private var _velocity:Velocity;
		private var _colorInit:ColorInit;
		private var _group:Group;
	}
}

