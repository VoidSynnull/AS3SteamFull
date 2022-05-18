package game.scenes.virusHunter.condoInterior.systems {

	// This stupid system helps move around draggable popup items in the search popup.
	// It is stuipid.

	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.creators.InteractionCreator;

	import game.scenes.virusHunter.condoInterior.components.Draggable;
	import game.scenes.virusHunter.condoInterior.components.SimpleEdge;
	import game.scenes.virusHunter.condoInterior.nodes.PopupDragNode;
	import game.systems.GameSystem;
	
	import org.osflash.signals.Signal;

	// This is for dragging something around on the screen.

	public class PopupDragSystem extends GameSystem {

		// Only one entity is dragged at a time.
		private var _currentDrag:Entity;

		public function PopupDragSystem():void {

			super( PopupDragNode, updateNode, nodeAdded, nodeRemoved );

		} //

		private function updateNode( node:PopupDragNode, time:Number ):void {
		} //

		// NOTE: Interaction does not correctly handle releaseOutside, so I need a custom releaseOutside handler.
		private function nodeAdded( node:PopupDragNode ):void {
		} //


		private function nodeRemoved( node:PopupDragNode ):void {
		} //

	} // End class

} // End package