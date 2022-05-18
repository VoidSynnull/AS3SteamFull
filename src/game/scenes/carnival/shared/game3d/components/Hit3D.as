package game.scenes.carnival.shared.game3d.components {

	import ash.core.Entity;
	
	import ash.core.Component;
	
	import game.scenes.carnival.shared.game3d.geom.Shape3D;
	
	import org.osflash.signals.Signal;

	public class Hit3D extends Component {

		public var shape:Shape3D;

		/**
		 * A hitType used to indicate what hits will test against this hit.
		 */
		public var hitType:int;

		/**
		 * A hit mask that masks which hit types to test for.
		 * if ( hit1.hitType &amp; hit2.hitCheck ) != 0 then hits between hit1 and hit2 will be tested.
		 */
		public var hitCheck:int;

		public var onHit:Signal;		// onHit( thisEntity, hitEntity )

		public function Hit3D( shape:Shape3D, code:int=0, check:int=0 ) {

			super();

			this.onHit = new Signal( Entity, Entity );

			this.shape = shape;
			this.hitType = code;
			this.hitCheck = check;

		} //

	} // End Hit3D

} // End package