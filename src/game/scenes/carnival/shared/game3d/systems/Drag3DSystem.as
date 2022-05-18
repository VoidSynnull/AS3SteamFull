package game.scenes.carnival.shared.game3d.systems {

	import flash.display.DisplayObjectContainer;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.geom.Vector3D;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.creators.InteractionCreator;
	
	import game.scenes.carnival.shared.game3d.components.Draggable3D;
	import game.scenes.carnival.shared.game3d.components.Motion3D;
	import game.scenes.carnival.shared.game3d.components.Spatial3D;
	import game.scenes.carnival.shared.game3d.nodes.Draggable3DNode;
	import game.scenes.virusHunter.condoInterior.components.Draggable;
	import game.scenes.virusHunter.condoInterior.components.SimpleEdge;
	
	import org.osflash.signals.Signal;

	public class Drag3DSystem extends System {

		private var dragNodes:NodeList;

		private var _currentDrag:Entity;

		public function Drag3DSystem() {

			super();

		} //

		override public function update( time:Number ):void {

			for( var node:Draggable3DNode = this.dragNodes.head as Draggable3DNode; node; node = node.next ) {

				this.updateNode( node, time );

			} //

		} //

		/**
		 * Going to skip verlet for the first version. can alter it later if it looks bad.
		 */
		public function updateNode( node:Draggable3DNode, time:Number ):void {

			if ( node.entity != this._currentDrag ) {
				return;
			}

			var clip:DisplayObjectContainer = node.display.displayObject;
			var tx:Number = clip.parent.mouseX;
			var ty:Number = clip.parent.mouseY;

			var draggable:Draggable3D = node.draggable;

			if ( draggable.bounds ) {
				
				var bounds:Rectangle = draggable.bounds;
				
				var edge:SimpleEdge = node.entity.get( SimpleEdge );
				if ( edge ) {
					
					if ( tx < bounds.left+edge.left ) {
						
						tx = bounds.left+edge.left;
						
					} else if ( tx+edge.right > bounds.right ) {
						tx = bounds.right - edge.right;
					}
					if ( ty < bounds.top+edge.top ) {
						ty = bounds.top+edge.top;
					} else if ( ty+edge.bottom > bounds.bottom ) {
						ty = bounds.bottom-edge.bottom;
					}
					
				} else {
					
					if ( tx < bounds.left ) {
						tx = bounds.left;
					} else if ( tx > bounds.right ) {
						tx = bounds.right;
					}
					if ( ty < bounds.top ) {
						ty = bounds.top;
					} else if ( ty > bounds.bottom ) {
						ty = bounds.bottom;
					}
					
				} // end (edge)
				
			} // end-if.
			
			node.spatial.x += ( tx - clip.x)/4;
			node.spatial.y += ( ty - clip.y)/4;

			draggable.onDrag.dispatch( node.entity, time );

		} //

		private function nodeAdded( node:Draggable3DNode ):void {

			var display:DisplayObjectContainer = node.display.displayObject;

			InteractionCreator.addToComponent( display, [ InteractionCreator.DOWN, InteractionCreator.UP ], node.interaction );
			
			node.interaction.down.add( this.mouseDown );
			node.interaction.up.add( this.mouseUp );
			
			if ( node.draggable.onStartDrag == null ) {
				node.draggable.onStartDrag = new Signal( Entity );
			}
			if ( node.draggable.onDrag == null ) {
				node.draggable.onDrag = new Signal( Entity, Number );
			}
			if ( node.draggable.onEndDrag == null ) {
				node.draggable.onEndDrag = new Signal( Entity );
			}

			display.addEventListener( MouseEvent.RELEASE_OUTSIDE, this.releaseOutside );

		} //

		private function nodeRemoved( node:Draggable3DNode ):void {
			
			node.draggable.onStartDrag.removeAll();
			node.draggable.onDrag.removeAll();
			node.draggable.onEndDrag.removeAll();
			
			node.interaction.down.remove( this.mouseDown );
			node.interaction.up.remove( this.mouseUp );
			
		} //

		private function releaseOutside( evt:MouseEvent ):void {

			if ( this._currentDrag != null ) {
				this.mouseUp( this._currentDrag );
			}

		} //
		
		private function mouseDown( e:Entity ):void {

			var draggable:Draggable3D = e.get( Draggable3D );

			if ( draggable.enabled ) {

				this._currentDrag = e;
				draggable.dragging = true;
				draggable.onStartDrag.dispatch( e );

			} //

		} //
		
		private function mouseUp( e:Entity ):void {

			var draggable:Draggable3D = e.get( Draggable3D );

			this._currentDrag = null;

			// Drag might have been disabled/cancelled.
			if ( draggable.dragging == true && draggable.enabled ) {
				
				draggable.dragging = false;
				draggable.onEndDrag.dispatch( e );
	
			} // End-if.

		} //

		override public function addToEngine( systemManager:Engine):void {

			this.dragNodes = systemManager.getNodeList( Draggable3DNode );
			for( var node:Draggable3DNode = this.dragNodes.head; node; node = node.next ) {

				this.nodeAdded( node );

			} //
			this.dragNodes.nodeAdded.add( this.nodeAdded );
			this.dragNodes.nodeRemoved.add( this.nodeRemoved );

			//this.motionNodes.nodeAdded.add( this.nodeAdded );

		} //

		override public function removeFromEngine( systemManager:Engine ):void {

			systemManager.releaseNodeList( Draggable3DNode );
			this.dragNodes = null;

		} //

	} // End Drag3DSystem

} // End package