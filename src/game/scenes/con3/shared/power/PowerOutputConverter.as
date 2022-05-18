package game.scenes.con3.shared.power
{
	public class PowerOutputConverter
	{
		public function PowerOutputConverter()
		{
			
		}
		
		/**
		 * Converts input to output. This method is intended to be overridden by
		 * any class that extends this class. This allows for customized output
		 * depending on the input and how th epower is to be handled.
		 */
		public function convert(power:Number, time:Number):Number
		{
			return power > 0 ? 1 : 0;
		}
	}
}