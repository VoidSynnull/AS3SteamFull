package game.data.photobooth
{
	public class TransformData
	{
		public var property:String;
		public var scale:Number;
		public var valueIncrement:Number;
		public var initVal:Number;
		public function TransformData(property:String, scale:Number = 1, valueIncrement:Number = NaN)
		{
			this.property = property;
			this.scale = scale;
			this.valueIncrement = valueIncrement;
		}
	}
}