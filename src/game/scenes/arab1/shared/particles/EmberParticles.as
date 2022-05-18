package game.scenes.arab1.shared.particles
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.data.TimedEvent;
	import game.util.BitmapUtils;
	import game.util.SceneUtil;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.GravityWell;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.EllipseZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class EmberParticles extends Emitter2D
	{
		public function init($group:Group, $color1:uint = 0xFF9900, $color2:uint = 0xFFFF99, $size:Number = 1.0, $vel:Number = 60, $accelY:Number = -350, $yOffset:Number = 0):void
		{
			_group = $group;
			
			var bitmapData:BitmapData = BitmapUtils.createBitmapData(new Dot($size));
			
			super.addInitializer( new BitmapImage(bitmapData, true) );
			
			_colorInit = new ColorInit($color1, $color2);
			_position = new Position( new EllipseZone( new Point(0,0+$yOffset), 55, 80 ) );
			_velocity = new Velocity( new EllipseZone( new Point(0,0), $vel, $vel ) );
			
			super.addInitializer( _colorInit );
			super.addInitializer( _position );
			super.addInitializer( _velocity );
			
			_lifetime = new Lifetime( 2, 0.5 );
			
			super.addInitializer( _lifetime );
			
			super.addAction( new Move() );
			super.addAction( new Fade() );
			super.addAction( new Age() );
			//super.addAction( new ScaleImage( 1.4, 0.1) );
			super.addAction( new Accelerate( 0, $accelY) );
		}
		
		public function initViewPort($group:Group, $width:Number, $height:Number):void{
			_group = $group;
			
			var bitmapData:BitmapData = BitmapUtils.createBitmapData(new Dot(1.5));
			
			super.addInitializer( new BitmapImage(bitmapData, true) );
			
			_colorInit = new ColorInit(0xF5E9FF);
			_position = new Position( new RectangleZone(0,0,$width,$height) );
			//_position = new Position( new EllipseZone( new Point(0,0), $width, $height ) );
			_velocity = new Velocity( new EllipseZone( new Point(0,0), 30, 30 ) );
			
			super.addInitializer( _colorInit );
			super.addInitializer( _position );
			super.addInitializer( _velocity );
			
			_lifetime = new Lifetime( 6, 0.5 );
			
			super.addInitializer( _lifetime );
			
			super.addAction( new Move() );
			super.addAction( new Fade() );
			super.addAction( new Age() );
			//super.addAction( new ScaleImage( 1.4, 0.1) );
			super.addAction( new Accelerate( 0, -200) );
		}
		
		public function puff():void{
			
			EllipseZone(_position.zone).xRadius = 55;
			EllipseZone(_position.zone).yRadius = 80;
			
			super.counter = new Steady(150);
			SceneUtil.addTimedEvent(_group, new TimedEvent(0.1, 1, stopPuff));
		}
		
		public function sparkle():void{
			super.counter = new Steady(45);
			SceneUtil.addTimedEvent(_group, new TimedEvent(4, 1, stopPuff));
		}
		
		public function stream():void{
			
			EllipseZone(_position.zone).xRadius = 4;
			EllipseZone(_position.zone).yRadius = 4;
			
			//EllipseZone(_velocity.zone).xRadius = 5;
			//EllipseZone(_velocity.zone).yRadius = 4;
			
			_lifetime.maxLifetime = -0.7;
			
			super.counter = new Steady(25);
			//SceneUtil.addTimedEvent(_group, new TimedEvent(3, 1, stopPuff));
		}
		
		public function stopPuff():void{
			super.counter = new Steady(0);
		}
		
		
		//private var _imageClass:ImageClass;
		private var _colorInit:ColorInit;
		private var _origSpatial:Spatial;
		private var _gravityWell:GravityWell;
		private var _lifetime:Lifetime;
		
		private var _group:Group;
		
		private var _position:Position;
		private var _velocity:Velocity;
		
	}
}