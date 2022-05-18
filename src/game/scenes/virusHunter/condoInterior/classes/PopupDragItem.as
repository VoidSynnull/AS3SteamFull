package game.scenes.virusHunter.condoInterior.classes {

	// Note: this class will break if the draggable class is ever removed from the associated entity.
	// Could avoid this complication by making this class a component and using a System, but
	// that would create additional problems as well. I'll think about it.

	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.scenes.virusHunter.condoInterior.components.Draggable;
	import game.scenes.virusHunter.condoInterior.components.ScaleBounce;
	import game.scenes.virusHunter.condoInterior.components.SimpleEdge;

	public class PopupDragItem {

		private var _entity:Entity;
		private var _draggable:Draggable;

		// Prize objects are the ones that will scale up and be presented to the user when dragged.
		// they are basically the things you are searching for in a search popup.
		public var isPrize:Boolean = false;
		public var prizeScale:Number = 2;	// how big the object gets once scaled up.

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

		public function PopupDragItem( group:Group, clip:DisplayObjectContainer ) {
	
			var e:Entity = new Entity();

			var d:Display = new Display( clip );
			d.interactive = true;

			e.add( d )
			e.add( new Spatial( clip.x, clip.y ) )
			e.add( new SimpleEdge( clip.width/2, clip.height/2, clip.width/2, clip.height/2 ) )
			e.add( new Interaction() );

			group.addEntity( e );			// need to do this first to get the interaction signals.

			this._draggable = new Draggable();
			e.add( _draggable );

			_draggable.onStartDrag.add( this.doStartDrag );
			_draggable.onEndDrag.add( this.doEndDrag );

			this._entity = e;

		} //

		public function disable():void {

			_draggable.disable();

		} //

		public function enable():void {

			_draggable.enable();

		} //

		public function makePrize( zoomScale:Number=NaN):void {

			if ( !isNaN( zoomScale ) ) {
				this.prizeScale = zoomScale;
			}
			this.isPrize = true;

		} //

		// REQUIRES the ScaleBounceSystem system.
		public function zoomItem( endScale:Number ):void {

			_draggable.disable();

			var scaleBounce:ScaleBounce = _entity.get( ScaleBounce );
			if ( !scaleBounce ) {

				scaleBounce = new ScaleBounce( endScale, zoomDone );
				_entity.add( scaleBounce );

			} else {

				scaleBounce.targetScale = endScale;
				scaleBounce.onScaleDone = this.zoomDone;
				scaleBounce.enabled = true;

			} //

		} //

		// Put item back after its been scaled up.
		public function unzoomItem():void {

			var scaleBounce:ScaleBounce = _entity.get( ScaleBounce );
			if ( !scaleBounce ) {

				// Can't directly callback to enable() because wrong number of parameters.
				scaleBounce = new ScaleBounce( 1, this.unzoomDone );
				_entity.add( scaleBounce );
				
			} else {
				
				scaleBounce.targetScale = 1;
				scaleBounce.onScaleDone = this.unzoomDone;
				scaleBounce.enabled = true;

			} //

			scaleBounce.damping = 0.2;

		} //

		private function unzoomDone( e:Entity ):void {
			this.enable();
		} //

		private function zoomDone( e:Entity ):void {

			if ( onFound != null) {
				onFound( this );
			}

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

			if ( onFound == null && isPrize == false ) {
				return;
			}

			if ( findDelay > 0 ) {

				_timer = findDelay;
				_draggable.onDrag.add( this.doDrag );

			} else {

				itemFound();
	
			} // end-if.

		} //

		private function itemFound():void {

			// bounce.
			if ( isPrize ) {
				bringToFront();
				zoomItem( prizeScale );
			} else {

				if ( onFound != null) {
					onFound( this );
				}
			}

		} // End function itemFound()

		// Called while an object is dragging.
		private function doDrag( e:Entity, time:Number ):void {

			this._timer -= time;
			if ( this._timer <= 0 ) {

				this._draggable.onDrag.remove( this.doDrag );
				this.itemFound();

			} //

		} //

		private function doEndDrag( e:Entity ):void {

			_draggable.onDrag.remove( this.doDrag );

		} //

		public function get entity():Entity {
			return _entity;
		}

		public function get draggable():Draggable {
			return _draggable;
		}

		// I assume the system itself will remove the entity from the group.
		// Remove any interaction signals as well.
		public function destroy():void {

			_entity = null;

		} //

	} // End PopupDragItem

} // End package