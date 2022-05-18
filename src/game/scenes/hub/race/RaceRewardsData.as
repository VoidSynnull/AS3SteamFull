package game.scenes.hub.race
{
	public class RaceRewardsData
	{
		public var rewards:Vector.<Reward>;
		public function RaceRewardsData(xml:XML = null)
		{
			parse(xml);
		}
		
		private function parse(xml:XML = null):void
		{
			if(xml == null)
				return;
			
			rewards = new Vector.<Reward>();
			for(var i:int = 0; i < xml.children().length(); ++i)
			{
				rewards.push(new Reward(xml.children()[i]));
			}
		}
		
		public function getRewardById(id:String):Reward
		{
			for each (var reward:Reward in rewards)
			{
				if(reward.id == id)
					return reward
			}
			return null;
		}
	}
}