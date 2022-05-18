package game.data.character.part
{
	import game.util.DataUtils;
	public class SkinPartId
	{	

		public function SkinPartId( partType:String = "", partId:String="" )
		{
			this.partType = DataUtils.getString(partType);
			this.partId = DataUtils.getString(partId);
		}
		
		public var partType:String;
		public var partId:String;
		
		/**
		 * Compare SkinPartId to determine if they are the same
		 * @param	skinPartId
		 * @return
		 */
		public function equals( skinPartId:SkinPartId ):Boolean
		{
			if ( skinPartId.partType == this.partType )
			{
				if ( skinPartId.partId == this.partId )
				{
					return true;
				}
			}
			return false
		}
		
		public function clone():SkinPartId
		{
			return new SkinPartId( this.partType, this.partId );
		}
		
		public function toString():String
		{
			return (" partType: " + this.partType + ", partId: " + this.partId );
		}
	}
}