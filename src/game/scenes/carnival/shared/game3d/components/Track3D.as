package game.scenes.carnival.shared.game3d.components {

	import ash.core.Entity;
	
	import ash.core.Component;

	/**
	 * Track something moving in 3d. Because I didn't bother making a general Spatial3D component,
	 * this has the obnoxious requirement of tracking both a Spatial and a ZDepthNumber z-value.
	 * Oh well.
	 */
	public class Track3D extends Component {

		public var _trackSpatial:Spatial3D;

		public var active:Boolean = false;

		public function Track3D( entity:Entity ) {

			super();
			this.trackEntity( entity );

		} //

		public function trackEntity( e:Entity ):void {

			this._trackSpatial = e.get( Spatial3D ) as Spatial3D;

		} //

	} // End Track3D
	
} // End package