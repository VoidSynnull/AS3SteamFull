package game.scenes.custom{
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.creators.InteractionCreator;
	
	import game.scenes.virusHunter.condoInterior.components.Draggable;
	import game.scenes.virusHunter.condoInterior.components.SimpleEdge;
	import game.scenes.virusHunter.condoInterior.nodes.DraggableNode;
	import game.systems.GameSystem;
	
	import org.osflash.signals.Signal;
	
	// This is for dragging something around on the screen.
	
	public class DropGameSystem extends GameSystem {
		
		// Only one entity is dragged at a time.
		private var _currentDrag:Entity;
		
		public function DropGameSystem():void {
			
			super( DraggableNode, updateNode, nodeAdded, nodeRemoved );
			
		} //
		
		private function updateNode( node:DraggableNode, time:Number ):void {
			
			if ( node.entity != _currentDrag ) {
				return;
			}
			
			var clip:MovieClip = node.display.displayObject as MovieClip;
			var tx:Number = clip.parent.mouseX;
			var ty:Number = clip.parent.mouseY;
			
			var draggable:Draggable = node.draggable;
			
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
			
			clip.x = node.spatial.x += ( tx - clip.x)/4;
			clip.y = node.spatial.y += ( ty - clip.y)/4;
			
			draggable.onDrag.dispatch( node.entity, time );
			
		} //
		
		// NOTE: Interaction does not correctly handle releaseOutside, so I need a custom releaseOutside handler.
		private function nodeAdded( node:DraggableNode ):void {
			
			InteractionCreator.addToComponent( node.display.displayObject, [ InteractionCreator.DOWN, InteractionCreator.UP ], node.interaction );
			
			node.interaction.down.add( this.mouseDown );
			node.interaction.up.add( this.mouseUp );
			
			node.draggable.onStartDrag = new Signal( Entity );
			node.draggable.onDrag = new Signal( Entity, Number );
			node.draggable.onEndDrag = new Signal( Entity );
			
			var display:DisplayObjectContainer = node.display.displayObject;
			display.addEventListener( MouseEvent.RELEASE_OUTSIDE, this.releaseOutside );
			
		} //
		
		private function releaseOutside( evt:MouseEvent ):void {
			
			if ( _currentDrag != null ) {
				mouseUp( _currentDrag );
			}
			
		} //
		
		private function mouseDown( e:Entity ):void {
			
			var draggable:Draggable = e.get( Draggable );
			
			if ( draggable.enabled ) {
				
				_currentDrag = e;
				draggable.dragging = true;
				draggable.onStartDrag.dispatch( e );
				
			} //
			
		} //
		
		private function mouseUp( e:Entity ):void {
			
			var draggable:Draggable = e.get( Draggable );
			
			_currentDrag = null;
			
			if(draggable)
			{
				// Drag might have been disabled/cancelled.
				if ( draggable.dragging == true && draggable.enabled ) {
					
					draggable.dragging = false;
					draggable.onEndDrag.dispatch( e );
					
				}
			}
			
		} //
		
		private function nodeRemoved( node:DraggableNode ):void {
			
			node.draggable.onStartDrag.removeAll();
			node.draggable.onDrag.removeAll();
			node.draggable.onEndDrag.removeAll();
			
			node.interaction.down.remove( this.mouseDown );
			node.interaction.up.remove( this.mouseUp );
			
		} //
		
	} // End class
	
}

 // End package