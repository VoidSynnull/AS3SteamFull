package game.data
{	
	import game.components.entity.State;
	import game.util.DataUtils;
	
	public class StateData
	{
		public function StateData( id:String = "", value:* = null )
		{
			invalidate = true;
			this.id = id;
			if( value != null )
			{
				_value = value;
			}
		}
		
		public var id:String;
		public var _parent:State;		// parent state this is within
		private var _invalidate:Boolean = false;	// flag denoting the need to apply/reapply
		public function get invalidate():Boolean	{ return _invalidate; }
		public function set invalidate( bool:Boolean ):void
		{
			_invalidate = bool;
			if ( bool )
			{
				if ( _parent )
				{
					_parent.invalidate = true;
				}
			}
		}
		
		protected var _value:*;
		public function get value():*	{ return _value; }
		public function set value( value:* ):void
		{
			if ( this.value != value )
			{
				this.invalidate = true;	// this sets parent invalidate as well
				_value = value;
			}
		}
		
		public function manualInvalidate( bool = true):void
		{
			invalidate = bool;
			
			if ( _parent )
			{
				_parent.invalidate = bool;
			}
			
			if( childrenStates )
			{
				for (var i:int = 0; i < childrenStates.length; i++) 
				{
					childrenStates[i].manualInvalidate( bool );
				}
			}
		}
		
		public function parse( xml:XML ):void
		{
			this.id = DataUtils.getString(xml.attribute("id"));
			_value = xml;
		}
		
		private var _parentStateData:StateData;			// a parent ColorAspectData that defines value
		public function get parentStateData():StateData	{ return _parentStateData; }
		public function set parentStateData( parentState:StateData ):void
		{
			_parentStateData = parentState;
			if ( parentState.childrenStates == null )
			{
				parentState.childrenStates = new Vector.<StateData>();
			}
			parentState.childrenStates.push( this );
		}
		
		public var childrenStates:Vector.<StateData>;	// children ColorAspectDatas who receive value
		public function addChildState( state:StateData ):StateData	
		{ 
			state.parentStateData = this;
			return state; 
		}
	}
}
