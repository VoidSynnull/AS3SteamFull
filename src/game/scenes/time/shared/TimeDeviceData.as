package game.scenes.time.shared
{

	public class TimeDeviceData
	{
		public var scene:Class;
		public var rotation:Number;
		public var date:String;
		public var event:String;
		public function TimeDeviceData(scene:Class, rotation:Number, date:String, event:String)
		{
			this.scene = scene;
			this.rotation = rotation;
			this.date = date;
			this.event = event;
		}
	}
}