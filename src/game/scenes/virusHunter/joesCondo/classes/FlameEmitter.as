package game.scenes.virusHunter.joesCondo.classes {
	
	import flash.geom.Point;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.ChooseInitializer;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.InitializerGroup;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscZone;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.PointZone;
	
	public class FlameEmitter extends Emitter2D {

		public function init():void {

			counter = new Steady( 64 );

			var grp1:InitializerGroup = new InitializerGroup();

			// red
			grp1.addInitializer( new ImageClass( Dot, [1, 0xDD0000 ], true ) );
			grp1.addInitializer( new Position( new DiscZone( new Point(0,0), 5, 0 ) ) );
			grp1.addInitializer( new Lifetime( 1, 2 ) );

			// orange.
			var grp2:InitializerGroup = new InitializerGroup();
			grp2.addInitializer( new ImageClass( Dot, [1, 0xFFAA00 ], true ) );
			grp2.addInitializer( new Position( new DiscZone( new Point(0,0), 3, 0 ) ) );
			grp2.addInitializer( new Lifetime( 0.8, 1.5 ) );

			// yellow
			var grp3:InitializerGroup = new InitializerGroup();
			grp3.addInitializer( new ImageClass( Dot, [1, 0xFFFF00 ], true ) );
			grp3.addInitializer( new Position( new DiscZone( new Point(0,0), 2, 0 ) ) );
			grp3.addInitializer( new Lifetime( 0.5, 1 ) );

			addInitializer( new ChooseInitializer( [ grp1, grp2, grp3 ] ) );

			addAction( new Age() );
			addAction( new Move() );
			addAction( new RandomDrift( 2, 0 ) );
			addAction( new Accelerate( 0, -10 ) );

		} //
		
	} // End FlameEmitter
	
} // End package