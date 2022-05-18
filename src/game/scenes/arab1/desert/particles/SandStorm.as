package game.scenes.arab1.desert.particles
{
	import flash.geom.Point;
	
	import engine.group.Group;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.ScaleAll;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.EllipseZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class SandStorm extends Emitter2D
	{
		
		public function init($group:Group, $x:Number, $y:Number, $width:Number, $height:Number, $particleSize:Number = 182, $yVariance:Number = 800):void
		{
			_group = $group;
			_imageClass = new ImageClass( Blob, [$particleSize], true );
			super.addInitializer( _imageClass );
			
			_colorInit = new ColorInit(0xCFB378, 0xCFB378);
			_position = new Position( new RectangleZone( $x, $y, $x+$width, $y+$height) );
			_velocity = new Velocity( new EllipseZone( new Point(0,0), 200, $yVariance ) );
			
			super.addInitializer( _colorInit );
			super.addInitializer( _position );
			super.addInitializer( _velocity );
			
			_lifetime = new Lifetime( 3, 0.5 );
			
			super.addInitializer( _lifetime );
			
			super.addAction( new Move() );
			super.addAction( new Fade(0.2,0) );
			super.addAction( new Age() );
			super.addAction( new Accelerate( -600, 0) );
			super.addAction( new ScaleAll(1, 2) );
		}
		
		public function stream():void{
			super.counter = new Steady(15);
		}
		
		private var _imageClass:ImageClass;
		private var _lifetime:Lifetime;
		private var _position:Position;
		private var _velocity:Velocity;
		private var _colorInit:ColorInit;
		private var _group:Group;
	}
}

