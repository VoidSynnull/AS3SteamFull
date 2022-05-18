package game.scenes.con3.shared.power
{
	public class PowerInputConverter
	{
		public function PowerInputConverter()
		{
			
		}
		
		public function convert(inputs:Array, time:Number):Number
		{
			var power:Number = 0;
			for each(var input:Number in inputs)
			{
				power += input;
			}
			return power;
		}
	}
}