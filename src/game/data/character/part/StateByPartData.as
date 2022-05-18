package game.data.character.part
{
	public class StateByPartData
	{	
		/**
		 * Specifies part-to-state relationship, used for both defining applying and receiving state.
		 * @param	partId - id of part holding state
		 * @param	partStateId - id of retrieved state
		 * @param	stateId - id of applied state
		 */
		public function StateByPartData( partId:String = "", partStateId:String = "", stateId:String = "" )
		{
			if ( partId != "" )
			{
				this.partId = partId;
			}
			if ( partStateId != "" )
			{
				this.partStateId = partStateId;
			}
			if ( stateId != "" )
			{
				this.stateId = stateId;
			}
		}
		
		public var partId:String;			// part id being referenced
		public var partStateId:String;		// colorId of part being referenced
		public var stateId:String;			// stateId applying/retrieving state
	}
}