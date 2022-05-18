package game.scenes.survival2.shared
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import game.components.ui.CardItem;
	import game.scenes.survival2.Survival2Events;
	import game.ui.card.CardContentView;
	import game.util.DataUtils;

	public class FishingPoleContentView extends CardContentView
	{
		/**
		 * Interface class for the card content
		 */
		public function FishingPoleContentView(container:DisplayObjectContainer = null) 
		{
			super(container);
		}
		
		/**
		 * Method to override, call by CardGroup within card creation sequence.
		 */
		override public function create( cardItem:CardItem, onComplete:Function = null ):void
		{
			super.unpause();
			super.loadFile(_assetPath, cardContentLoaded, cardItem, onComplete);
		}

		private function cardContentLoaded(asset:DisplayObjectContainer, cardItem:CardItem, handler:Function = null):void
		{
			this.groupContainer.addChild(asset);
			
			var events:Survival2Events = new Survival2Events();

			// setup pole frame
			var poleLabel:String = "noLaces";
			var fishingPole:MovieClip = asset["fishingPole"] as MovieClip;
			var shoelace1:Boolean = shellApi.checkItemUsedUp(events.SHOELACE1);
			var shoelace2:Boolean = shellApi.checkItemUsedUp(events.SHOELACE2);
			if(shoelace1 && shoelace2)
			{
				poleLabel = "twoLaces";
			}
			else if(shoelace1 || shoelace2)
			{
				poleLabel = "oneLace";
			}
			fishingPole.gotoAndStop(poleLabel);
			
			// setup hook & bait
			var bait:String = cardItem.cardData.conditionals[0].value;
			if( !DataUtils.validString(bait) )
			{
				bait = "none";
			}

			var hook:MovieClip = fishingPole["hook"];
			hook.alpha = ( shellApi.checkItemUsedUp(events.HOOK)) ? 1 : 0;
			hook.gotoAndStop(bait);
			
			
			if(handler != null) { handler(); }
		}
		
		private var _assetPath:String = "items/survival2/fishingPole.swf"
	}
} 