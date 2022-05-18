package game.scenes.con2.shared.cardGame
{
	import flash.display.DisplayObjectContainer;
	
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.scenes.con2.shared.cardGame.systems.CCGScoreSystem.CCGSCoreSystem;
	import game.scenes.con2.shared.turnBased.TurnBasedGroup;
	import game.util.SceneUtil;
	import game.util.TweenUtils;
	
	public class TurnBasedCCG extends TurnBasedGroup
	{
		private var cardGame:CardGame;
		private const DEFEATED:String = "defeated_";
		public function TurnBasedCCG(container:DisplayObjectContainer)
		{
			super(container);
		}
		
		override public function start():void
		{
			index = 0;
			cardGame = parent as CardGame;
			setTurnIndexByPlayerId(cardGame.ENEMY);
			
			if(shellApi.checkEvent( DEFEATED+cardGame.enemyId) && cardGame.hasDialog("start2", false))
				cardGame.playMessage("start2");
			else
				cardGame.playMessage("start", false);
			
			CCGSCoreSystem(getSystem(CCGSCoreSystem)).scoreDetermined.add(resultsAreIn);
			
			for(var i:int = 0; i < players.length; i++)
			{
				cardGame.dealCards(players[i], 3);
			}
			
			SceneUtil.delay(parent, 4, Command.create(cardGame.setUser, currentPlayer));
		}
		
		private function setTurnIndexByPlayerId(playerId:String):void
		{
			var i:int = players.indexOf(getPlayerById(playerId));
			if(i >= 0)
			{
				index = i;
				currentPlayer = getPlayerById(playerId);
			}
		}
		
		public function actionComplete():void
		{
			nextTurn();
		}
		
		override protected function nextTurn():void
		{
			CCGUser(currentPlayer.get(CCGUser)).myTurn = false;
			++index;
			if(index >= players.length)
				index = 0;
			currentPlayer = players[index];
			
			if(index > 0)		
				cardGame.setUser(currentPlayer);
			else
				result();
		}
		
		override protected function result():void
		{
			var enemy:CCGUser = getPlayerById(cardGame.ENEMY).get(CCGUser);
			var player:CCGUser = getPlayerById(cardGame.PLAYER).get(CCGUser);
			
			preActiveLogic(enemy, player);
			
			cardNumber = scoresDetermined = 0;
			
			animateCard(cards[cardNumber], true);
		}
		
		private function preActiveLogic(enemy:CCGUser, player:CCGUser):void
		{
			cards = new Vector.<UseCardData>();
			
			var enemyBlocks:String;// enemy actions that are blocked
			var playerBlocks:String; // player actions that are blocked
			
			var enemyAttack:CCGCard;
			if(enemy.attack.card != null)
				enemyAttack = enemy.attack.card.get(CCGCard);
			
			var enemyBounty:CCGCard;
			if(enemy.bounty.card != null)
				enemyBounty = enemy.bounty.card.get(CCGCard);
			
			var playerAttack:CCGCard;
			if(player.attack.card != null)
				playerAttack= player.attack.card.get(CCGCard);
			
			var playerBounty:CCGCard;
			if(player.bounty.card != null)
				playerBounty = player.bounty.card.get(CCGCard);
			
			playerBlocks = determineBlock(enemyAttack, playerAttack, playerBounty);
			playerBlocks += determineBlock(enemyBounty, playerAttack, playerBounty);
			
			enemyBlocks = determineBlock(playerAttack, enemyAttack, enemyBounty);
			enemyBlocks += determineBlock(playerBounty, enemyAttack, enemyBounty);
			
			// blocks are the highest priority so they have to be determined before anything
			
			trace("player blocks: " + playerBlocks + " enemy blocks: " + enemyBlocks);
			
			cards.push(new UseCardData(enemy.attack.card, true, (enemyBlocks.indexOf(ATTACK) >= 0), player, enemy),
				new UseCardData(player.attack.card, true, (playerBlocks.indexOf(ATTACK) >= 0), enemy, player),
				new UseCardData(enemy.bounty.card, false, (enemyBlocks.indexOf(BOUNTY) >= 0), player, enemy),
				new UseCardData(player.bounty.card, false, (playerBlocks.indexOf(BOUNTY) >= 0), enemy, player));
			
			additionalCards = new Vector.<UseCardData>();
			for each(var useCardData:UseCardData in cards)
			{
				activatePreTurnEffects(useCardData);
			}
			cards = cards.concat(additionalCards);
		}
		
		private function activatePreTurnEffects(useCardData:UseCardData):void
		{
			if(useCardData.card == null || useCardData.blocked)
				return;
			
			var otherCardData:UseCardData;
			
			switch(useCardData.card.effect)
			{
				case CCGEffects.DECEIVE:
				{
					for each(otherCardData in cards)
					{
						if(otherCardData.card == null || otherCardData.user.id == useCardData.user.id)
							continue;
						otherCardData.opponent = useCardData.opponent;
						otherCardData.user = useCardData.user;
					}
					for each(otherCardData in additionalCards)
					{
						if(otherCardData.card == null || otherCardData.user.id == useCardData.user.id)
							continue;
						otherCardData.opponent = useCardData.opponent;
						otherCardData.user = useCardData.user;
					}
					break;
				}
				case CCGEffects.ENRAGE:
				{
					for each(otherCardData in cards)
					{
						if(otherCardData.card == null || otherCardData.user.id == useCardData.user.id)
							continue;
						if(otherCardData.attacking)
							additionalCards.push(new UseCardData(useCardData.entity, useCardData.attacking, false, useCardData.opponent, useCardData.user));
					}
					break;
				}
				case CCGEffects.GREED:
				{
					for each(otherCardData in cards)
					{
						if(otherCardData.card == null || otherCardData.user.id == useCardData.user.id)
							continue;
						if(!otherCardData.attacking)
							additionalCards.push(new UseCardData(useCardData.entity, useCardData.attacking, false, useCardData.opponent, useCardData.user));
					}
					break;
				}
			}
		}
		
		private var additionalCards:Vector.<UseCardData>;
		private var cards:Vector.<UseCardData>;
		private var cardNumber:uint;
		private var activeCard:UseCardData;
		
		private function animateCard(data:UseCardData, activate:Boolean):void
		{
			if(data.entity)
			{
				cardGame.flipCard(data.user, data.entity, false,true, true);
				SceneUtil.delay(this, 1, Command.create(useCardVisual, data, activate));
			}
			else if(activate)
				useCard(data);
		}
		
		private function useCard(data:UseCardData):void
		{
			activeCard = cards[cardNumber];
			++cardNumber;
			
			trace("used card: " + cardNumber + " out of: " + cards.length);
			if(data.card != null)
			{
				trace(data.card.id + " " + data.card.value + " " + data.card.effect + " " + data.attacking + " " + data.blocked);
				
				if(!data.blocked)
				{
					var method:Function;
					if(data.card.value == 0)
						method = useNextCard;
					else
						method = Command.create(activateCard, data);
					
					if(cardGame.hasDialog(data.user.id + "_used_" + data.card.effect,false))
					{
						cardGame.playMessage(data.user.id + "_used_" + data.card.effect,false, method);
						_waitForDialog = true;
					}
					else
						method();
				}
				else 
				{
					if(cardGame.hasDialog(data.user.id + "_blocked",false))
						cardGame.playMessage(data.user.id + "_blocked",false, useNextCard);
					else
						useNextCard();
				}
			}
			else
			{
				if(scoresDetermined < cards.length)
					resultsAreIn();
			}
		}
		
		private function activateCard(data:UseCardData):void
		{
			switch(data.card.effect)
			{
				case CCGEffects.STEAL:
				{
					if(data.opponent.score.validPoints(-1))
					{
						data.opponent.stolenFrom = true;
						data.opponent.score.removePoints(1);
						data.user.score.addPoints(1);
					}
					break;
				}
					
				case CCGEffects.DRAW:
				{
					cardGame.dealCards(getPlayerById(data.user.id));
					break;
				}
					
				case CCGEffects.SKIP:
				{
					data.opponent.skip = true;
					break;
				}
			}
			
			if(data.attacking)
				data.opponent.score.removePoints(data.card.value);
			else
				data.user.score.addPoints(data.card.value);
		}
			
		
		private function useNextCard():void
		{
			if(scoresDetermined < cards.length)
				SceneUtil.delay(parent, 1, resultsAreIn);
		}
		
		private function useCardVisual(data:UseCardData, toUse:Boolean):void
		{
			if(toUse)
				TweenUtils.entityTo(data.entity, Spatial, .5, {scale:1.1, onComplete:Command.create(useCard, data)});
			else
				TweenUtils.entityTo(data.entity, Spatial, .5, {scale:1});
		}
		
		private var scoresDetermined:int;
		
		private function resultsAreIn():void
		{
			if(cardGame.dialogWindow.messageComplete.numListeners > 1 && _waitForDialog)
				return;
			_waitForDialog = false;
			
			animateCard(activeCard, false);
			
			++scoresDetermined;
			
			trace("played cards: " + scoresDetermined + " out of: " + cards.length);
			if(scoresDetermined == cards.length)
			{
				var player:CCGUser = getPlayerById(cardGame.PLAYER).get(CCGUser);
				var enemy:CCGUser = getPlayerById(cardGame.ENEMY).get(CCGUser);
				if(player.hand.length == 0 && enemy.hand.length == 0)
				{
					trace("all cards used");
					if(player.score.score == enemy.score.score)
						cardGame.setWinner();
					else
					{
						if(player.score.score > enemy.score.score)
							cardGame.setWinner(player);
						else
							cardGame.setWinner(enemy);
					}
					return;
				}
				else
				{
					if(player.score.hasWinningScore() && enemy.score.hasWinningScore())
					{
						cardGame.setWinner();
						return;
					}
					else
					{
						if(player.score.hasWinningScore())
						{
							cardGame.setWinner(player);
							return;
						}
						if(enemy.score.hasWinningScore())
						{
							cardGame.setWinner(enemy);
							return;
						}
					}
				}
				SceneUtil.delay(parent, 2, Command.create(cardGame.clearBoard, currentPlayer));
			}
			else
			{
				if(cardNumber < cards.length)
				{
					trace("next");
					animateCard(cards[cardNumber],true);
				}
			}
		}
		
		private function determineBlock(blocker:CCGCard, attack:CCGCard, bounty:CCGCard):String
		{
			var block:String = "";
			
			// if the attack demands a sacrafice
			if(attack != null && attack.effect == CCGEffects.SACRIFICE)
			{
				//if there is no sacrafice the attacker is blocked
				if(bounty == null)
					block = ATTACK;
				else//otherwise the sacrafice is blocked
					block = BOUNTY;
				return block;
			}
			// if the bounty demands a sacrafice
			if(bounty != null && bounty.effect == CCGEffects.SACRIFICE)
			{
				//if there is no sacrafice the bounty is blocked
				if(attack == null)
					block = BOUNTY;
				else//otherwise the sacrafice is blocked
					block = ATTACK;
				return block;
			}
			
			if(blocker == null || blocker.effect != CCGEffects.BLOCK)
				return block;
			
			var value:uint = blocker.value;
			
			if(attack != null)
			{
				if(attack.value <= value)
					block += ATTACK;
			}
			if(bounty != null)
			{
				if(bounty.value <= value)
					block += BOUNTY;
			}
			return block;
		}
		
		private var _waitForDialog:Boolean;
		
		private const ATTACK:String = "attack";
		private const BOUNTY:String = "bounty";
	}
}