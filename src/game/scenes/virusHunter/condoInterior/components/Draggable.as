package game.scenes.virusHunter.condoInterior.components {

	import flash.geom.Rectangle;
	
	import ash.core.Component;
	
	import org.osflash.signals.Signal;

	public class Draggable extends Component {

		// These should technically be signals. but its overkill since they will probably never be used in that context.
		// These notifications pass the entity as their only parameter:
		public var onStartDrag:Signal;
		public var onEndDrag:Signal;

		public var onDrag:Signal;			// notification function gives: onDrag( e:Entity, time:Number )

		// Bounds are only applied to the center coordinate of the object's spatial.
		// Currently, the object's edges are not taken into account.
		public var bounds:Rectangle;

		public var enabled:Boolean = true;
		public var dragging:Boolean = false;

		public function Draggable() {

			super();

		} //

		public function stopDrag():void {

			this.dragging = false;

		} //

		public function disable():void {

			this.enabled = false;
			this.dragging = false;

		} //

		public function enable():void {

			this.enabled = true;

		} //

	} // End ClickTarget

} // End package