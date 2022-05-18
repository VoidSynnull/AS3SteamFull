package game.scenes.virusHunter.shared.components
{
	import ash.core.Component;
	
	public class Melee extends Component
	{
		public function Melee()
		{
			
		}
		
		public var minimumDamageEffectInterval:Number = .5;
		public var timeSinceLastDamageEffect:Number = .5;
		public var alwaysOn:Boolean = true;
		public var active:Boolean = true;
		public var range:Number = 40;
	}
}