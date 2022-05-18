package game.scenes.virusHunter.shipDemo.systems
{
	import flash.text.TextField;
	
	import ash.core.Engine;
	import ash.tools.ListIteratingSystem;
	
	import game.scenes.virusHunter.shipDemo.nodes.ScoreNode;
	
	public class ScoreSystem extends ListIteratingSystem
	{
		public function ScoreSystem(scoreDisplay:TextField)
		{
			super(ScoreNode, updateNode);
			
			_scoreDisplay = scoreDisplay;
		}
		
		private function updateNode(node:ScoreNode, time:Number):void
		{
			if(node.pointValue._redeem)
			{
				node.pointValue._redeem = false;
				this.score += node.pointValue.value;
			}
			
			if(_lastUpdate > .2)
			{
				_lastUpdate = 0;
				if(Number(_scoreDisplay.text) < this.score)
				{
					_scoreDisplay.text = String(Number(_scoreDisplay.text) + 10);
				}
			}
			else
			{
				_lastUpdate += time;
			}
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			systemManager.releaseNodeList(ScoreNode);
			super.removeFromEngine(systemManager);
		}
		
		public var score:Number = 0;
		private var _scoreDisplay:TextField;
		private var _lastUpdate:Number = 0;
	}
}