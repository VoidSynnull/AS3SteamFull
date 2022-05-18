package game.scenes.survival3.shared.components
{
	import ash.core.Component;
	
	public class RadioSignal extends Component
	{
		public var groundLevel:Number;
		public var height:Number;
		public var signalStrength:Number;
		public var maxSignalHeight:Number;
		public var minSignalStrength:Number;
		public var hasGoodSignal:Boolean;
		public function RadioSignal(groundLevel:Number, maxSignalHeight:Number = 5000, minSignalStrength:Number = 1)
		{
			height = 0;
			signalStrength = 0;
			hasGoodSignal = false;
			
			this.maxSignalHeight = maxSignalHeight;
			this.minSignalStrength = minSignalStrength;
			this.groundLevel = groundLevel;
		}
	}
}