package game.scenes.lands.shared.components {

	/**
	 * 
	 * the lands UI has over 89 buttons that all need their own input. making each of
	 * these buttons an entity with ToolTip objects is too expensive. A single input
	 * component collects and dispatches input for all of them.
	 *
	 */

	import flash.events.IEventDispatcher;
	import flash.utils.Dictionary;
	
	import ash.core.Component;
	
	import game.scenes.lands.shared.classes.EventListener;

	public class InputManager extends Component {

		/**
		 * IEventDispatcher object -> Vector.<EventListener>
		 * 
		 * don't write to this directly. it's only for systems.
		 */
		public var _objectEvents:Dictionary;

		/**
		 * IEventDispatcher object -> Vector.<EventListener>
		 * 
		 * when individual objects have their listeners paused, their event lists
		 * are moved here. note that globally pausing ALL event listeners doesn't
		 * move the listeners to this dictionary.
		 */
		public var pausedEvents:Dictionary;

		/**
		 * If paused it means all the event listeners have actually been removed
		 * from the objects, but they still exist so they can be added back when unpaused.
		 */
		private var _paused:Boolean;

		public function InputManager() {

			this._objectEvents = new Dictionary();
			this.pausedEvents = new Dictionary();

		} //

		[ Inline ]
		final public function get paused():Boolean {
			return this._paused;
		}

		[ Inline ]
		final public function set paused( b:Boolean ):void {

			if ( this._paused == b ) {
				return;
			} //
			this._paused = b;

			if ( this._paused ) {

				this.unpauseComponent();			// remove all event listeners.

			} else {

				this.pauseComponent();		// add all event listeners.

			} //

		} //

		/**
		 * user must not register the same event type/function to the same object. that is standard through flash
		 * and I don't check for it here.
		 * 
		 * at the time attempting to add a listener to a paused object is a very bad idea.
		 */
		public function addEventListener( obj:IEventDispatcher, evt:String, func:Function ):void {

			var evtList:Vector.<EventListener> = this._objectEvents[ obj ] as Vector.<EventListener>;
			
			if ( evtList == null ) {
				// create new event list for this object.
				evtList = this._objectEvents[ obj ] = new Vector.<EventListener>();
			}

			evtList.push( new EventListener( obj, evt, func ) );

			if ( !this.paused ) {
				// if paused, event should not actually attach.
				obj.addEventListener( evt, func );
			} //

		} //

		public function removeEventListener( obj:IEventDispatcher, type:String, func:Function ):void {

			var evtList:Vector.<EventListener> = this._objectEvents[ obj ] as Vector.<EventListener>;

			// indicates when the event is being removed from a paused list.
			var pauseList:Boolean = false;

			if ( evtList == null ) {

				// check paused object.
				evtList = this.pausedEvents[ obj ];
				if ( !evtList ) {
					return;
				} //

				pauseList = true;

			} //

			var evt:EventListener;
			for( var i:int = evtList.length-1; i >= 0; i-- ) {

				evt = evtList[i];

				if ( evt.eventType != type || evt.listener != func ) {
					continue;
				}

				// found the event.
				if ( !this.paused && !pauseList ) {

					// if paused, the event listener will not be currently attached.
					obj.removeEventListener( type, func );
					
				} //

				evtList[i] = evtList[ evtList.length-1 ];
				evtList.pop();

			} // end for-loop.

			if ( evtList.length == 0 ) {

				if ( pauseList ) {

					// remove list from pause list.
					delete this.pausedEvents[ obj ];

				} else {

					// remove from regular list.
					delete this._objectEvents[ obj ];

				} // end-if.

			} //

		} //

		/**
		 * pause all events for a given dispatcher.
		 * an object must have all of its events paused - can't be selective.
		 */
		public function pauseListeners( obj:IEventDispatcher ):void {

			var evtList:Vector.<EventListener> = this._objectEvents[ obj ];

			if ( !evtList ) {
				return;
			}

			delete this._objectEvents[ obj ];

			// remove the listeners.
			var evt:EventListener;
			for( var i:int = evtList.length-1; i >= 0; i-- ) {

				evt = evtList[i];
				if ( !this.paused ) {
					// if the component is paused, there won't be an event listener here.
					obj.removeEventListener( evt.eventType, evt.listener );
				}

			} //

			this.pausedEvents[obj] = evtList;

		} //

		/**
		 * currently it seems like it would be an error to unpause an object that has not already
		 * been paused. it seems the existing events would be lost. this could be fixed by merging
		 * the event lists at the end?
		 */
		public function unpauseListeners( obj:IEventDispatcher ):void {

			var evtList:Vector.<EventListener> = this.pausedEvents[ obj ];
			
			if ( !evtList ) {
				return;
			}

			delete this.pausedEvents[ obj ];
			
			// remove the listeners.
			var evt:EventListener;
			for( var i:int = evtList.length-1; i >= 0; i-- ) {

				evt = evtList[i];
				// the whole component might still be paused.
				if ( !this.paused ) {
					obj.addEventListener( evt.eventType, evt.listener );
				}

			} //
			
			this._objectEvents[obj] = evtList;

		} //

		public function removeListeners( obj:IEventDispatcher ):void {

			var evtList:Vector.<EventListener> = this._objectEvents[ obj ];
			if ( evtList == null ) {

				// check for paused events.
				evtList = this.pausedEvents[ obj ];

				if ( evtList != null ) {

					// event list was found in paused events. delete the reference.
					delete this.pausedEvents[ obj ];
					// note that none of the events are attached, since the events were found in the paused list.
					evtList.length = 0;

				} //

				return;

			} //

			// event list was found in objectEvents. delete the reference.
			delete this._objectEvents[ obj ];

			if ( this.paused ) {
				// none of the events are attached.
				evtList.length = 0;
				return;
			}

			var evt:EventListener;
			for( var i:int = evtList.length-1; i >= 0; i-- ) {

				evt = evtList[i];
				obj.removeEventListener( evt.eventType, evt.listener );

			} //

			evtList.length = 0;

		} //

		override public function destroy():void {

			this.paused = true;

			var evt:EventListener;
			var evtList:Vector.<EventListener>;

			for ( var obj:IEventDispatcher in this._objectEvents ) {

				evtList = this._objectEvents[ obj ];
				delete this._objectEvents[ obj ];

				for( var i:int = evtList.length-1; i >= 0; i-- ) {

					evt = evtList[i];
					obj.removeEventListener( evt.eventType, evt.listener );

				}
				evtList.length = 0;

			} //

			for each ( evtList in this.pausedEvents ) {

				evtList.length = 0;

			} //

			//this._objectEvents = null;
			//this.pausedEvents = null;
			
			super.destroy();
			
		} //

		private function pauseComponent():void {

			var evt:EventListener;
			for each ( var evtList:Vector.<EventListener> in this._objectEvents ) {

				for( var i:int = evtList.length-1; i >= 0; i-- ) {

					evt = evtList[i];
					evt.obj.removeEventListener( evt.eventType, evt.listener );

				} //

			} //

		} //

		private function unpauseComponent():void {

			var evt:EventListener;
			for each ( var evtList:Vector.<EventListener> in this._objectEvents ) {
				
				for( var i:int = evtList.length-1; i >= 0; i-- ) {
					
					evt = evtList[i];
					evt.obj.addEventListener( evt.eventType, evt.listener );
					
				} //
				
			} //

		} //

	} // class
	
} // package