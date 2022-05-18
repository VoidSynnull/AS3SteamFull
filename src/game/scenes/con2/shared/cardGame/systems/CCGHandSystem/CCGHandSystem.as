package game.scenes.con2.shared.cardGame.systems.CCGHandSystem
{
	import flash.display.DisplayObject;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.systems.GameSystem;
	import game.util.EntityUtils;
	import game.util.TweenUtils;
	
	public class CCGHandSystem extends GameSystem
	{
		public function CCGHandSystem()
		{
			super(CCGHandNode, updateNode);
		}
		
		public function updateNode(node:CCGHandNode, time:Number):void
		{
			var spatial:Spatial;
			var hand:Vector.<Entity> = node.hand.user.hand;
			var width:Number = node.spatial.width / node.spatial.scaleX;
			var centerY:Number = node.spatial.height / 2 / node.spatial.scaleY;
			var fraction:int = hand.length + 1;
			var card:Entity;
			
			if(node.hand.takeCurrentSelection)
			{
				node.hand.takeCurrentSelection = false;
				if(node.hand.selectedCard != null)
				{
					var index:uint = node.hand.user.hand.indexOf(node.hand.selectedCard);
					node.hand.user.hand.splice(index, 1);
				}
				node.hand.selectedCard = null;
			}
			
			if(node.hand.selectedCard != node.hand.user.currentSelection)
			{
				if(node.hand.selectedCard != null)
				{
					TweenUtils.entityTo(node.hand.selectedCard, Spatial, .5, {scale:1, y:centerY});
					var display:DisplayObject = EntityUtils.getDisplayObject(node.hand.selectedCard);
					display.parent.setChildIndex(display, 1 + node.hand.user.hand.indexOf(node.hand.selectedCard));
				}
				node.hand.selectedCard = node.hand.user.currentSelection;
				if(node.hand.selectedCard != null)
				{
					TweenUtils.entityTo(node.hand.selectedCard, Spatial, .5, {scale:1.5, y:0});
					Display(node.hand.selectedCard.get(Display)).moveToFront();
				}
			}
			
			for(var i:int = 0; i < hand.length; i++)
			{
				card = hand[i];
				spatial = card.get(Spatial);
				if( spatial != null )
				{
					spatial.x = width * (i + 1) / fraction;
					if(card == node.hand.selectedCard)
						continue;
					spatial.y = centerY;
				}
			}
		}
	}
}