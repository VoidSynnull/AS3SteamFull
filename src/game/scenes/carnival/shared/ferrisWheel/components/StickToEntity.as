package game.scenes.carnival.shared.ferrisWheel.components {

	import ash.core.Entity;
	
	import ash.core.Component;
	import engine.components.Spatial;

	public class StickToEntity extends Component {

		public var offsetX:Number;
		public var offsetY:Number;

		public var entity:Entity;
		public var entitySpatial:Spatial;

		public function StickToEntity( entity:Entity, offX:Number, offY:Number ) {

			super();

			this.entity = entity;
			this.entitySpatial = entity.get( Spatial );

			this.offsetX = offX;
			this.offsetY = offY;

		} //

		public function setEntity( e:Entity ):void {

			this.entity = e;
			this.entitySpatial = e.get( Spatial );

		} //

	} // End StickToEntity

} // End package