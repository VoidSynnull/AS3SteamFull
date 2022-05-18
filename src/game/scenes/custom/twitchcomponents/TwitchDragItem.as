package game.scenes.custom.twitchcomponents{
	
	// Note: this class will break if the draggable class is ever removed from the associated entity.
	// Could avoid this complication by making this class a component and using a System, but
	// that would create additional problems as well. I'll think about it.
	
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.components.timeline.Timeline;
	import game.scenes.custom.twitchcomponents.DraggableComponent;
	import game.scenes.virusHunter.condoInterior.components.SimpleEdge;
	
	public class TwitchDragItem {
		
		private var _entity:Entity;
		private var _draggable:DraggableComponent;
		
		// Used to time delays from the start of a drag to when the onFound notification is triggered.
		private var _timer:Number;
		
		// how long you have to drag the object, in seconds, before it is 'found'
		public var findDelay:Number = 0.25;
		
		/**
		 * Function called when this object is found/dragged.  format: onFound( thePopupItem:PopupDragItem )
		 * onFound is called AFTER any find delays + bounce effects.
		 */
		public var onFound:Function;
		
		/**
		 * Like onFound, but called the first time an item is touched, whether or not it has a time delay.
		 */
		public var onTouched:Function;
		public var popped:Boolean = false;
		public var firstTouch:Boolean = true;
		
		public function TwitchDragItem( group:Group, clip:DisplayObjectContainer, timeline:Timeline )
		{
			var e:Entity = new Entity();
			
			var d:Display = new Display( clip );
			d.interactive = true;
			
			e.add( d )
			e.add( new Spatial( clip.x, clip.y ) )
			e.add( new SimpleEdge( clip.width/2, clip.height/2, clip.width/2, clip.height/2 ) )
			e.add( new Interaction() );
			
			group.addEntity( e );			// need to do this first to get the interaction signals.
			
			this._draggable = new DraggableComponent();
			e.add( _draggable );
			
			_draggable.timeline = timeline;
			e.add(timeline);
			_draggable.onStartDrag.add( this.doStartDrag );
			_draggable.onEndDrag.add( this.doEndDrag );
			
			this._entity = e;
		}
		
		public function disable():void {
			
			_draggable.disable();
			
		} //
		
		public function enable():void {
			
			_draggable.enable();
			
		} //
		
		
		public function bringToFront():void {
			
			var clip:DisplayObjectContainer = _entity.get( Display ).displayObject as DisplayObjectContainer;
			clip.parent.setChildIndex( clip, clip.parent.numChildren-1 );
			
		} //
		
		// By default, if we don't have an onFound function, we don't listen for the drag events.
		private function doStartDrag( e:Entity ):void {
			
			if ( this.onTouched != null ) {
				onTouched( this );
			}
			
			if ( findDelay > 0 && this.firstTouch == false ) {
				
				_timer = findDelay;
				_draggable.onDrag.add( this.doDrag );
				
			} 
			
			if ( this.firstTouch == true)
			{
				
				this.popped = true;
				this.firstTouch = false;
				
			}
			
		} //
		
		
		
		// Called while an object is dragging.
		private function doDrag( e:Entity, time:Number ):void {
			
			this._timer -= time;
			if ( this._timer <= 0) {
				
				this._draggable.onDrag.remove( this.doDrag );
				
				
			} //
			
		} //
		
		private function doEndDrag( e:Entity ):void {
			
			_draggable.onDrag.remove( this.doDrag );
			
		} //
		
		public function get entity():Entity {
			return _entity;
		}
		
		public function get draggable():DraggableComponent {
			return _draggable;
		}
		
		// I assume the system itself will remove the entity from the group.
		// Remove any interaction signals as well.
		public function destroy():void {
			
			_entity = null;
			
		} //
		
	} // End PopupDragItem
	
}



// End package