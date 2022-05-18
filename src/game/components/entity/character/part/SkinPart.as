package game.components.entity.character.part
{	
	import ash.core.Component;
	
	import game.util.DataUtils;
	
	import org.osflash.signals.Signal;
	
	/**
	 * A component that helps define the look of anything made out of parts.
	 * Contains information about a partular aspect of the look ( assets, colors, states, etc. )
	 */
	public class SkinPart extends Component
	{
		public function SkinPart( id:String = "", value:* = null )
		{
			this.id = id;
			if ( value != null )	{ setValue( value ); }
			loaded = new Signal( SkinPart );
		}
		
		public var id:String;						// skin name, includes parts names ( shirt, eyes, arm1 )
		public var _invalidate:Boolean = false;		// flag that the value has been changed/reassigned and needs ot be processed by SkinSystem
		public var loaded:Signal;					// dispatched when SkinPart has complete loading a new value (happens in SkinSystem), passes owning Entity with dispatch
		
		/**
		 * Flag notifying SkinSystem that asset needs updating, could removing current asset or loading a new one.
		 */
		public var refreshDisplay:Boolean;
		/**
		 * Flag determining if part shoudl be hidden or not, this gets mapped to the Display visible.  
		 */
		public var hidden:Boolean = false;
		/**
		 * Flag notifying SkinSystem that a new part asset must be loaded. 
		 */
		public var reload:Boolean = false;
		public var empty:Boolean = false;		// if set to true removes children within display

		public var restart:Boolean = false;		// restarts timelines associates with skinPart
		public var lock:Boolean = false;		// prevent value from being changed until unlocked
		
		private var _value:*;					// can be name of an item, a hex color, or a state.  Value depends on type.
		/**
		 * Current value of the skin part.
		 * @return 
		 */
		public function get value():*	{ return _value; }
		
		private var _permanent:*;				
		/**
		 * Value that will replace current value when revert is called.
		 * @return 
		 */
		public function get permanent():*		{ return _permanent; }	

		private var _saveValue:Boolean;			// flag to see if current value should be saved to profile
		public function get saveValue():Boolean	{ return _saveValue; }
		public function saveComplete():void		{ _saveValue = false; }

		
		
		/**
		 * Sets the SkinPart's value.
		 * @param nextValue
		 * @param isPermanent
		 * 
		 */
		public function setValue( nextValue:*, isPermanent:Boolean = true ):void
		{
			if ( !lock )
			{
				if( DataUtils.isValidStringOrNumber( nextValue ) )
				{
					if ( nextValue == PREVIOUS_VALUE )
					{
						// do not change value, do not restart timeline
					}
					else if ( nextValue == DEFAULT_VALUE )
					{
						if(	revertValue() )	// revert to permanent
						{
							_invalidate = true;
						}
					}
					else
					{
						if( typeof(nextValue) == "string" )	// make value lowercase, handles possibly invalid capitalization for asset within xml
						{
							nextValue = String(nextValue).toLowerCase();
						}
						
						if( nextValue == EMPTY )			// if already empty, do not invalidate for systems
						{
							if( _value != EMPTY )	
							{
								_value = nextValue;
								_invalidate = true;
							}
						}
						else
						{
							// NOTE :: nextValue can equal current value, this means that the value will be refreshed (timeline reset)
							_value = nextValue;
							_invalidate = true;
						}
						
						if ( isPermanent && ( _permanent != nextValue ) )
						{
							_permanent = nextValue;
							_saveValue = true;
						}
					}
				}
			}
		}
		
		/**
		 * Sets current value back to the permanent value
		 */
		public function revertValue():Boolean
		{
			if ( _value != _permanent )
			{
				if ( _permanent )
				{
					setValue( _permanent, true );
				}
				else
				{
					this.remove();
				}
				return true;
			}
			return false;
		}
		
		/**
		 * Makes current value the permanent value
		 */
		public function confirmValue():void
		{
			_permanent = _value;
		}
		
		/**
		 * If the current value is equal to the permanent value
		 */
		public function isPermanent():Boolean
		{
			return ( _value == _permanent );
		}
		
		/**
		 * Assigns an "empty" value
		 */
		public function remove( isPermanent:Boolean = true ):void
		{
			this.setValue( SkinPart.EMPTY, isPermanent );
		}
		
		public function get isEmpty():Boolean
		{
			return ( value == EMPTY );
		}
		
		public static const EMPTY:String = "empty";
		public static const PREVIOUS_VALUE:String = "previous";	// signals not to change value, allow previous value to remain.
		public static const DEFAULT_VALUE:String = "default";	// signals to revert to default value, which is the permanent value.
		
	}
}
