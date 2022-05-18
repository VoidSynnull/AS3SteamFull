package game.scenes.lands.shared.particles {

	import flash.display.DisplayObject;
	import flash.geom.Point;
	
	import engine.components.Display;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ColorsInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.AccelerateToMouse;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.EllipseZone;

	public class GlitterEffect extends Emitter2D {

		//private var ellipse:EllipseZone;
		private var _display:DisplayObject;

		public function GlitterEffect( displayObject:DisplayObject, followObj:Display ) {

			this.addActivity( new FollowDisplay( followObj, displayObject ) );

			//displayObject.filters = [ new BlurFilter( 2, 2, 3 ) ];

			this.useInternalTick = true;
			
			_display = displayObject;

		} //

		public function init():void {

			this.counter = new Steady( 16 );

			// the [1] is the parameter to the Dot constructor, in this case, radius.
			super.addInitializer( new ImageClass( Dot, [2], true ) );

			super.addInitializer( new Position( new EllipseZone( new Point( 0, -20 ), 10, 10 ) ) );
			super.addInitializer( new Velocity( new EllipseZone( new Point( 0, 0 ), 50, 50 ) ) );
			super.addInitializer( new ColorsInit( [ 0xFFFFFF, 0x88CFFF ] ) );
			super.addInitializer( new ScaleImageInit( 0.5, 1 ) );
			super.addInitializer( new Lifetime( 2 ) );

			super.addAction( new Age() );
			//super.addAction( new AntiGravity( 6000, 0, 0 ) ); //doesn't do much, and probably expensive
			super.addAction( new Move() );
			super.addAction( new Fade( 0.8, 0 ) );
			super.addAction( new AccelerateToMouse(1000, _display) );

		} // init()

		public function setGlitterColors( colors:Array ):void {

			var colorInit:ColorsInit;

			// find the color initializer.
			for( var i:int = this.initializers.length-1; i >= 0; i-- ) {

				colorInit = this.initializers[i] as ColorsInit;
				if ( colorInit == null ) {
					continue;
				}

				colorInit.colors = colors;
				return;

			} //

		} //

	} // class

} // package

