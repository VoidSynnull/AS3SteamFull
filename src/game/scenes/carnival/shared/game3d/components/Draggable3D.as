package game.scenes.carnival.shared.game3d.components {

	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import ash.core.Component;
	
	import org.osflash.signals.Signal;

	/**
	 * Throw component allows user to drag an object in a 3D space.
	 */
	public class Draggable3D extends Component {

		/**
		 * If true, throw component is auotomatically removed after object is thrown.
		 */
		public var singleThrow:Boolean = true;

		public var enabled:Boolean = true;
		public var dragging:Boolean = false;

		public var bounds:Rectangle;

		public var onStartDrag:Signal = new Signal( Entity );
		public var onDrag:Signal = new Signal( Entity, Number );
		public var onEndDrag:Signal = new Signal( Entity );

		public function Draggable3D() {

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

	} // End Draggable3D
	
} // End package