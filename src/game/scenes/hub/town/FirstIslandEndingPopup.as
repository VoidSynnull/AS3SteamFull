package game.scenes.hub.town
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.text.TextField;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Spatial;
	
	import game.creators.ui.ButtonCreator;
	import game.scenes.ftue.FtueEvents;
	import game.scenes.map.map.Map;
	import game.ui.popup.IslandEndingPopup;
	import game.util.TextUtils;
	
	public class FirstIslandEndingPopup extends IslandEndingPopup
	{
		public var explore:Boolean;
		public function FirstIslandEndingPopup(container:DisplayObjectContainer=null)
		{
			super(container);
			super.message = "Continue your adventure!";
			super.hasStoreButton = false;
			super.hasRankButton = false;
			explore = false;
			//super.buttonY = 250;
			
			hasContinueButton = true;
			
			_events = new FtueEvents();
		}
		
		override protected function setupCompletedIslandText():void
		{
			var textField:TextField = this.screen.content["completedIsland"];
			textField.height = textField.height + 200;
			textField = TextUtils.refreshText(textField);
			textField.text = message;
			textField.mouseEnabled = false;
		}
		
		override protected function setupContinueButton():void
		{
			var clip:MovieClip = this.screen.content.continueButton;

			if(this.hasContinueButton && !this.hasBonusQuestButton)
			{
				var textField:TextField = TextUtils.refreshText(clip.description);
				textField.text = "Explore Home!";
				textField.mouseEnabled = false;
				var entity:Entity = ButtonCreator.createButtonEntity(clip, this, this.onContinueClicked, null, null, null, false);
				entity.add(new Id(clip.name));
			}
			else
			{
				clip.parent.removeChild(clip);
			}
		}
		
		override protected function onContinueClicked(entity:Entity):void
		{
			scrubLastIsland();
			explore = true;
			super.close();
		}
		
		override protected function setupPlayButton():void
		{
			var clip:MovieClip = this.screen.content.islandButton;
			if( hasPlayButton )
			{
				var entity:Entity = ButtonCreator.createButtonEntity(clip, this, this.onIslandButtonClicked, null, null, null, false);
				entity.add(new Id(clip.name));
				
				var spatial:Spatial = entity.get(Spatial);
				
				var textField:TextField = TextUtils.refreshText(clip["description"]);
				textField.text = "Visit the Map!";
				textField.y += 8;
			}
			else
			{
				clip.parent.removeChild(clip);
			}
		}
		
		override protected function onIslandButtonClicked(entity:Entity):void
		{
			scrubLastIsland();
			shellApi.loadScene(Map);
		}
		
		private function scrubLastIsland():void
		{
			shellApi.profileManager.active.previousIsland = "";
			shellApi.profileManager.active.island = "";
		}

		private var _events:FtueEvents;
	}
}