package game.data.animation.entity
{
	import flash.utils.Dictionary;
	
	/**
	 * Rig data for a particular character variant, contains PartData for all parts.
	 */
	public class RigData
	{
		public var type : String;				// type of character/entity
		public var assetPath : String;			// relative path to assets
		public var dataPath : String;			// relative path to data
		public var partDatas : Dictionary;		// Dictionary of PartData
		public var partNames : Vector.<String>;	// NOTE :: this maintains the correct ordering for layering, just helps, not entirely necessary
		
		public function RigData()
		{
			partDatas = new Dictionary();
			partNames = new Vector.<String>;	
		}

		public function addPartData( partData:PartRigData ):void
		{
			partDatas[partData.id] = partData;
			partNames.push(partData.id);
		}
		
		public function getPartData( partId:String ):PartRigData
		{
			return partDatas[partId];
		}
	}
}