package game.scenes.virusHunter.condoInterior.classes {
	
	import flash.geom.Point;
	
	import org.flintparticles.common.counters.Pulse;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.DeathZone;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.zones.PointZone;
	import org.flintparticles.twoD.zones.RectangleZone;

	public class DropletEmitter extends Emitter2D {

		private var color:int;
		private var radius:Number;

		private var groundY:Number;

		private var bx:Number;
		private var by:Number;

		/**
		 * emitters do this annoying thing where they think they exist in the top,left corner of the screen.
		 */
		public function DropletEmitter( x:Number, y:Number, dropColor:int=0xFEFE60, dropRadius:Number=3, maxDrop:Number=130 ) {

			super();

			this.color = dropColor;
			this.radius = dropRadius;

			this.groundY = maxDrop;

			this.bx = x;
			this.by = y;

		} //

		public function init():void {

			this.counter = new Pulse( 0.9, 1 );

			this.addInitializer( new ImageClass( Dot, [this.radius, this.color ], true ) );
			this.addInitializer( new Position( new PointZone( new Point( bx, by ) ) ) );

			this.addAction( new DeathZone( new RectangleZone( bx-100, by + this.groundY, bx + 100, by + this.groundY + 400 ) ) );
			this.addAction( new Move() );
			this.addAction( new Accelerate( 0, 500 ) );

		} //

	} // End DropletEmitter

} // End package