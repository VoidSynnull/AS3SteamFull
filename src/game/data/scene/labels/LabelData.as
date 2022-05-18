package game.data.scene.labels 
{
	import flash.geom.Point;

	public class LabelData 
	{
		public var type:String;  
		public var id:String;
		public var text:String;
		public var x:Number;
		public var y:Number;
		//public var asset:String;
		public var offset:Point;

		public function LabelData( type:String = "", text:String = "") 
		{
			this.type = type;
			this.text = text;
		}

		public function toString():String {
			return '[LabelData type:' + type + ' id:' + id + ' text:' + text + ']';
		}
	}
}