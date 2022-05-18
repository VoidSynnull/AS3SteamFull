package game.scenes.lands.shared.classes {

	import flash.events.IEventDispatcher;

	public class EventListener {

		public var obj:IEventDispatcher;
		public var eventType:String;

		public var listener:Function;

		//public var grouping:Object;

		public function EventListener( obj:IEventDispatcher, type:String, listener:Function ) {

			this.obj = obj;
			this.eventType = type;
			this.listener = listener;

		} //
		
	} // class
	
} // package