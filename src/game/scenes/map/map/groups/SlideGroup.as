package game.scenes.map.map.groups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Interaction;
	import engine.creators.InteractionCreator;
	
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.data.ads.AdTrackingConstants;
	import game.data.ads.AdvertisingConstants;
	import game.managers.ads.AdManager;
	import game.util.EntityUtils;
	
	public class SlideGroup extends PageItem
	{
		public const SLIDE_BUTTON_OFFSET_X:int = 70;
		public const SLIDE_BUTTON_OFFSET_Y:int = 50;
		
		public function SlideGroup(container:DisplayObjectContainer = null)
		{
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.init(container);
			
			this.load();
		}
		
		override public function load():void
		{
			this.loadFile("slides.swf", this.slidesLoaded);
		}
		
		private function slidesLoaded(clip:MovieClip):void
		{
			this.groupContainer.addChild(clip);
			
			var entity:Entity = EntityUtils.createSpatialEntity(this, clip);
			BitmapTimelineCreator.convertToBitmapTimeline(entity);
			
			var interaction:Interaction = InteractionCreator.addToEntity(entity, [InteractionCreator.CLICK]);
			interaction.click.add(this.onSlideClicked);
			
			this.loaded();
		}
		
		private function onSlideClicked(entity:Entity):void
		{
			var timeline:Timeline = entity.get(Timeline);
			var frame:int = timeline.currentIndex + 1;
			
			if(frame >= timeline.totalFrames)
			{
				frame = 0;
			}
			
			timeline.gotoAndStop(frame);
			
			// if MMQ, then track
			if (islandFolder.indexOf(AdvertisingConstants.AD_PATH_KEYWORD) != -1)
			{
				var arr:Array = islandFolder.split("/");
				var campaignName:String = arr[1];
				AdManager(super.shellApi.adManager).track(campaignName, AdTrackingConstants.TRACKING_MAP_POPUP_IMPRESSION, "Slide " + (frame+1));
			}
		}
	}
}