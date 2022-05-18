package game.scenes.custom.LoopingPopupSystems
{
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import game.util.DataUtils;

	public class ObstacleData
	{
		public var obstacle:String;
		public var position:Point;
		public var rotation:Number;
		public var rotationVelocity:Number;
		public var entity:Entity;
		public function ObstacleData(xml:XML)
		{
			position = DataUtils.getPoint(xml);
			obstacle = DataUtils.getString(xml.child("clip")[0]);
			rotation = DataUtils.getNumber(xml.rotation);
			rotationVelocity = DataUtils.getNumber(xml.rotationVelocity);
		}
	}
}