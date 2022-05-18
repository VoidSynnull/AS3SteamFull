package game.scenes.con2.shared.cardGame.systems.CCGAISystem
{
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	import ash.tools.ListIteratingSystem;
	
	import game.scenes.con2.shared.cardGame.CCGCard;
	import game.scenes.con2.shared.cardGame.CCGEffects;
	import game.scenes.con2.shared.cardGame.CCGScore;
	import game.scenes.con2.shared.cardGame.CCGUser;
	
	public class CCGAISystem extends ListIteratingSystem
	{
		private var effectRatings:Dictionary;
		public function CCGAISystem()
		{
			super(CCGAINode, updateNode);
			effectRatings = new Dictionary();
			effectRatings[CCGEffects.BOTH] = 10;
			effectRatings[CCGEffects.DECEIVE] = 9;
			effectRatings[CCGEffects.BLOCK] = 8;
			effectRatings[CCGEffects.SKIP] = 7;
			effectRatings[CCGEffects.GREED] = 4;
			effectRatings[CCGEffects.STEAL] = 3;
			effectRatings[CCGEffects.ENRAGE] = 3;
			effectRatings[CCGEffects.DRAW] = 2;
			effectRatings[CCGEffects.NONE] = 0;
			
		}
		
		public function updateNode(node:CCGAINode, time:Number):void
		{
			if(!node.data.myTurn)
				return;
			
			node.ai.time += time;
			
			if(node.ai.time < node.ai.decisionTimes)
				return;
			
			node.ai.time = 0;
			
			if(node.data.hand.length == 0 && node.data.state == CCGUser.PICK)
				node.data.state == CCGUser.PLAY;
			
			if(node.data.state == CCGUser.PLAY)
			{
				node.ai.game.turnBaseGroup.actionComplete();
				return;
			}
			
			if(node.ai.type == CCGAI.SMART)
			{
				// decision tries to make best decision for itself
				// tries to make biggest impact on its own score
				// tries to hinder players score when behind
				// utilizes effects	inteligently
				makeSmartDecision(node);
				return;
			}
			
			if(node.ai.type == CCGAI.TO_13)
			{
				// decision is only trying to reach 13
				tryToMake13(node);
				return;
			}
			
			if(node.ai.type == CCGAI.RANDOM)
			{
				// decision is purely random
				makeRandomDecision(node);
			}
		}
		
		private function makeRandomDecision(node:CCGAINode):void
		{
			if(node.data.state == CCGUser.PICK)
			{
				if(node.data.currentSelection == null)
				{
					var card:Entity = selectRandCard(node.data.hand);
					node.ai.game.selectCard(card, node.data);
				}
				else
					node.ai.game.selectCard(node.data.currentSelection, node.data);
			}
			else
			{
				var rand:Number = Math.random();
				
				var opponent:CCGScore = node.ai.game.turnBaseGroup.getPlayerById(node.ai.game.PLAYER).get(CCGUser).score;
				
				if(rand > .5 && opponent.score > 0)
					node.ai.placement = node.ai.game.ATTACK;
				else
					node.ai.placement = node.ai.game.BOUNTY;
				
				placeCard(node);
			}
		}
		
		private function tryToMake13(node:CCGAINode):void
		{
			if(node.data.state == CCGUser.PICK)
			{
				if(node.data.currentSelection == null)
				{
					var selection:Entity = selectHighestValuedCard(node.data.hand, node.data.score);
					node.ai.placement = node.ai.game.BOUNTY;
					if(selection == null)
					{
						selection = selectHighestValuedCard(node.data.hand, node.data.score,false);
						node.ai.placement = node.ai.game.ATTACK;
					}
					node.ai.game.selectCard(selection, node.data);
				}
				else
					node.ai.game.selectCard(node.data.currentSelection, node.data);
			}
			else
				placeCard(node);
		}
		
		private function makeSmartDecision(node:CCGAINode):void
		{
			var card:CCGCard;
			if(node.data.state == CCGUser.PICK)
			{
				if(node.data.currentSelection == null)
				{
					var selection:Entity;
					var opponent:CCGScore = node.ai.game.turnBaseGroup.getPlayerById(node.ai.game.PLAYER).get(CCGUser).score;
					
					selection = selectHighestValuedCard(node.data.hand, node.data.score, true, true);
					node.ai.placement = node.ai.game.BOUNTY;
					if(selection == null)
					{
						selection = selectHighestValuedCard(node.data.hand, opponent, false, true);
						node.ai.placement = node.ai.game.ATTACK;
					}
					else
					{
						card = selection.get(CCGCard);
						if(card.value <= 2)
						{
							if(opponent.score > node.data.score.score + card.value)
								node.ai.placement = node.ai.game.ATTACK;
						}
					}
					node.ai.game.selectCard(selection, node.data);
				}
				else
					node.ai.game.selectCard(node.data.currentSelection, node.data);
			}
			else
				placeCard(node);
		}
		
		private function placeCard(node:CCGAINode):void
		{
			var dock:Entity = node.ai.game.getEntityById(node.data.id + node.ai.game.DOCK);
			var slot:Entity = node.ai.game.getEntityById(node.data.id + node.ai.placement);
			node.ai.game.placeCardInSlot(slot, dock, node.data);
		}
		
		private function selectRandCard(hand:Vector.<Entity>):Entity
		{
			var rand:int = int(Math.random() * hand.length);
			return hand[rand];
		}
		
		private function selectHighestValuedCard(hand:Vector.<Entity>, score:CCGScore, bounty:Boolean = true, favorEffects:Boolean = false):Entity
		{
			var val:int = -1;
			var selection:Entity;
			var current:Entity;
			var card:CCGCard;
			var valDirection:int = 1;
			if(!bounty)
				valDirection = -1;
			
			var effectRating:int = -1;
			
			for(var i:int = 0; i < hand.length; i++)
			{
				current = hand[i];
				card = current.get(CCGCard);
				if(score.validPoints(card.value * valDirection))
				{
					if(score.winningPoints(card.value) && bounty && card.effect != CCGEffects.STEAL || score.winningPoints(card.value + 1) && card.effect == CCGEffects.STEAL && bounty || !bounty && score.winningPoints(1) && card.effect == CCGEffects.STEAL)
					{
						return current;
					}
					if(favorEffects && score.score != 0)
					{
						if(effectRatings[card.effect] > effectRating && effectRatings[card.effect] > val || card.value > effectRating && card.value > val)
						{
							val = card.value;
							selection = current;
							effectRating = effectRatings[card.effect];
						}
					}
					else
					{
						if(card.value > val)
						{ 
							val = card.value;
							selection = current;
						}
					}
				}
			}
			return selection;
		}
	}
}