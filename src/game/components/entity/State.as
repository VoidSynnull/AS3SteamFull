package game.components.entity
{	
	import flash.utils.Dictionary;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import game.data.StateData;
	
	import org.osflash.signals.Signal;

	public class State extends Component
	{
		public function State()
		{
			_states = new Dictionary();
			updateComplete = new Signal( Entity );
		}
		
		public var updateComplete:Signal;
		public var invalidate:Boolean = false;	// can use invalidate to notify any changes to states
		private var _hasChanged:Boolean = false;	// used as a flag that exists for a single update cycle.
		public function set hasChanged(bool:Boolean):void
		{
			_hasChanged = bool;
		}
		public function get hasChanged():Boolean	{ return _hasChanged; }	// used as a flag that exists for a single update cycle.
		
		private var _states:Dictionary = new Dictionary();
		public function get states():Dictionary 	{ return _states; }

		public function addState( id:String, value:* = null ):StateData
		{
			var stateData:StateData;
			if ( _states[id] == null ) 
			{
				stateData = new StateData( id );
				stateData._parent = this;

				if ( value != null )
				{
					stateData.value = value
				}
				stateData.invalidate = true;
				
				_states[id] = stateData;
			}
			else
			{
				trace( "Notification :: State :: addState :: state with id : " + id + " has already been added." );
				stateData = _states[id];
			}
			
			return stateData;
		}
		
		public function addStateData( stateData:StateData ):StateData
		{
			if ( _states[stateData.id] == null ) 
			{
				_states[stateData.id] = stateData;
				stateData._parent = this;
			}
			else
			{
				trace( "Notification :: State :: addState :: state with id : " + stateData.id + " has already been added." );
				stateData = _states[stateData.id];
			}
			
			return stateData;
		}
		
		public function setState( id:String, value:* ):void
		{
			var stateData:StateData = _states[id];
			if( stateData )
			{
				StateData(_states[id]).value = value;	// if value has changed, both StateData and Sate get invalidated
			}
		}
		
		public function getState( id:String ):StateData
		{
			return _states[id];
		}
		
		public function getLast():StateData
		{
			for each( var states:StateData in _states )
			{
				return states;
			}
			return null;
		}
	}
}