package game.adparts.creators
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.DisplayGroup;
	
	import game.adparts.parts.AdPoster;
	import game.creators.ui.ToolTipCreator;
	import game.components.entity.Sleep;
	import game.data.ui.ToolTipType;
	
	public class AdPosterCreator
	{
		/**
		 * Constructor
		 */
		public function AdPosterCreator():void
		{
		}
		
		/**
		 * Create Poster entity
		 * @param group Scene to add entity to
		 * @param posterClip
		 * @param posterData
		 * @param interactiveClip
		 * @return Entity
		 */
		public function create(group:DisplayGroup, posterClip:MovieClip, posterData:Object, interactiveClip:DisplayObjectContainer):Entity
		{
			//create poster entity
			var poster:Entity = new Entity().add(new AdPoster(posterData, group, interactiveClip));
			var display:Display = new Display(posterClip);
			display.isStatic = true;
			poster.add(display);
			poster.add(new Id(posterClip.name));
			poster.add(new Spatial());
			poster.add(new Sleep());
			
			// add enity to group
			group.addEntity(poster);
			
			// add tooltip
			var offset:Point = new Point(posterClip.width/2, posterClip.height/2);
			var text:String;
			// set enter text if photobooth or quest
			if ((posterData.enterPhotoBooth) || (posterData.enterQuest))
				text = "Enter";
			ToolTipCreator.addToEntity(poster, ToolTipType.CLICK, text, offset);
			
			// create interaction for clicking on poster
			var interaction:Interaction = InteractionCreator.addToEntity(poster, [InteractionCreator.CLICK], posterClip);
			interaction.click.add(clickPoster);
			
			// if has multiple frames then assume rollovers based on two frames
			trace("AdPosterCreator :: create : gotoplay check");
			if(!posterData.gotoAndPlay && !posterData.autoPlay)
			{
				trace("AdPosterCreator :: create : gotoplay not null");
				if (posterClip.totalFrames != 1)
				{
					trace("AdPosterCreator :: create : gotoplay frames != 1");
					posterClip.gotoAndStop(1);
					posterClip.addEventListener(MouseEvent.ROLL_OVER, buttonRollover);
					posterClip.addEventListener(MouseEvent.ROLL_OUT, buttonRollout);
				}
				else
				{
					trace("AdPosterCreator :: create : gotoplay frames else");
					// if one frame then hide clip
					poster.get(Display).alpha = 0;
					posterClip.alpha = 0;
				}
			}
			return poster;
		}
		
		/**
		 * Handle mouse clicks
		 * @param	clickedEntity	Poster entity clicked on
		 */
		private function clickPoster(clickedEntity:Entity):void
		{
			clickedEntity.get(AdPoster).clickPoster(clickedEntity.get(Id).id);
		}
		
		/**
		 * When rolling over poster clip 
		 * @param aEvent
		 */
		private function buttonRollover(aEvent:MouseEvent):void
		{
			MovieClip(aEvent.currentTarget).gotoAndStop(2);
		}
		
		/**
		 * When rolling out of poster clip 
		 * @param aEvent
		 */
		private function buttonRollout(aEvent:MouseEvent):void
		{
			MovieClip(aEvent.currentTarget).gotoAndStop(1);
		}	
	}
}