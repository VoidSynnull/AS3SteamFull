package game.ar.ArPopup
{
	import flash.display.Sprite;
	import flash.utils.Dictionary;

	public class FacialLandMarks
	{
		public var masksApplied:Array;
		public var facialLandMarks:Dictionary;
		public var container:Sprite;
		public function FacialLandMarks(landMarkers:Vector.<int> = null)
		{
			masksApplied = [];
			facialLandMarks = new Dictionary();
			if(landMarkers != null)
			{
				for(var i:int = 0; i < landMarkers.length; i++)
				{
					facialLandMarks[landMarkers[i]] = new FacialLandMarkData(landMarkers[i]);
				}
			}
		}
		
		public function GetLandMarkById(id:int):FacialLandMarkData
		{
			if(facialLandMarks.hasOwnProperty(id))
				return facialLandMarks[id];
			return null;
		}
	}
}