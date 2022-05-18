package game.data.character.part
{
	import game.util.DataUtils;
	public class DirectionData
	{	
		/**
		 * NOT IMPLEMENTED YET
		 * set an instance name of any clips that should match the direction (x scale) of the character (default is right).
		 * The tags within will set the frame labels to switch to, if no tags are specified will default to frame 1 = right, frame 2 = left
		 * @param	instanceName
		 * @param	rightLabel
		 * @param	leftLabel
		 */
		public function DirectionData( instanceName:String = "", rightLabel:String = "", leftLabel:String = "" )
		{
			this.instanceData = new InstanceData( instanceName );

			if ( rightLabel != "" )
			{
				this.rightLabel = rightLabel;
			}
			if ( leftLabel != "" )
			{
				this.leftLabel = leftLabel;
			}
		}
		
		public var instanceData:InstanceData;
		public var rightLabel:String;
		public var leftLabel:String;
	}
}