package game.scenes.con2.shared.cardGame.systems.CCGScoreSystem
{
	import ash.core.Entity;
	
	import engine.managers.SoundManager;
	
	import game.components.timeline.Timeline;
	import game.systems.GameSystem;
	import game.util.AudioUtils;
	
	import org.osflash.signals.Signal;
	
	public class CCGSCoreSystem extends GameSystem
	{
		public function CCGSCoreSystem()
		{
			super(ScoreDisplayNode, updateNode);
			scoreDetermined = new Signal();
		}
		
		public var scoreDetermined:Signal;
		
		public function updateNode(node:ScoreDisplayNode, time:Number):void
		{
			if(node.display.user.score.score != node.display.score)
			{
				node.display.time += time * node.display.visualSpeed;
				
				if(node.display.time < 1)
					return;
				
				node.display.scoreDifference = node.display.user.score.score - node.display.score;
				
				if(node.display.scoreDifference > 0)
					addPoints(node);
				else
					removePoints(node);
				
				if(node.display.score == node.display.user.score.score)
				{
					node.display.original = node.display.score;
					if(!node.display.user.stolenFrom)
						scoreDetermined.dispatch();
					else
						node.display.user.stolenFrom = false;
				}
				
				node.display.time = 0;
			}
		}
		
		private function removePoints(node:ScoreDisplayNode):void
		{
			--node.display.score;
			if(node.display.score >= 0)
			{
				var slot:Entity = node.children.children[node.display.score];
				Timeline(slot.get(Timeline)).gotoAndPlay(LOOSE_GEM);
				playSound(REMOVE_GEM);
			}
			else
				node.display.score = node.display.user.score.score = 0;
		}
		
		private function addPoints(node:ScoreDisplayNode):void
		{
			++node.display.score;
			if(node.display.score <= node.display.user.score.WINNING_SCORE)
			{
				var prefix:String = ADD_GEM;
				if(node.display.score < 10)
				{
					prefix += "0";
				}
				playSound(prefix, node.display.score);
				
				var slot:Entity = node.children.children[node.display.score - 1];
				Timeline(slot.get(Timeline)).gotoAndPlay(GET_GEM);
			}
			else
			{
				playSound(TOO_MANY_GEMS);
				node.display.user.score.score = node.display.original;
				node.display.score = node.display.user.score.WINNING_SCORE;
			}
		}
		
		private function playSound(prefix:String, num:int = 0):void
		{
			if(num == 0)
				AudioUtils.play(group, SoundManager.EFFECTS_PATH + prefix);
			else
				AudioUtils.play(group, SoundManager.EFFECTS_PATH + prefix + num + MP3);
		}
		
		private const PINGS:uint 			= 9;
		
		private const MP3:String			= ".mp3";
		private const ADD_GEM:String		= "get_gem_";//13
		private const REMOVE_GEM:String		= "gem_break_01.mp3";
		private const TOO_MANY_GEMS:String	= "access_denied.mp3";
		
		private static const GET_GEM:String = "getGem";
		private static const LOOSE_GEM:String = "looseGem";
	}
}