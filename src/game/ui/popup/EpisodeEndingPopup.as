package game.ui.popup
{
	import flash.display.DisplayObjectContainer;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.data.island.IslandEvents;
	import game.data.scene.DoorData;
	import game.data.scene.DoorParser;
	import game.scenes.map.map.Map;
	import game.ui.elements.DialogPicturePopup;
	
	public class EpisodeEndingPopup extends DialogPicturePopup
	{
		protected var _currentIslandXML:XML;
		protected var _nextIslandXML:XML;
		
		public const PLAY_NEXT_EPISODE_TEXT:String = "NEXT EPISODE";
		public const PLAY_ANOTHER_ISLAND_TEXT:String = "BACK TO MAP";
		public const TO_BE_CONTINUED_TEXT:String = "To be continued!";
		
		public function EpisodeEndingPopup(container:DisplayObjectContainer = null)
		{
			super(container, false, true);
			updateText(null, TO_BE_CONTINUED_TEXT, PLAY_ANOTHER_ISLAND_TEXT);
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			if(this.shellApi.islandEvents.nextEpisodeEvents)
			{
				const nextIslandEvents:IslandEvents = new this.shellApi.islandEvents.nextEpisodeEvents();
				
				if(nextIslandEvents.accessible)
				{
					if(nextIslandEvents.earlyAccess)
					{
						if(this.shellApi.profileManager.active.isMember)
						{
							this.updateText(null, PLAY_NEXT_EPISODE_TEXT);
						}
						else
						{
							this.updateText(null, TO_BE_CONTINUED_TEXT);
						}
					}
					else
					{
						this.updateText(null, PLAY_NEXT_EPISODE_TEXT);
					}
				}
				else
				{
					this.updateText(null, TO_BE_CONTINUED_TEXT);
				}	
			}
			else
			{
				//We don't have a next island, so why would we have 2 buttons that both send you to the Map? Exactly. Removing one.
				this._button2.get(Spatial).x = this.screen.content.width / 2;
				this._button2.get(Display).displayObject.x = this.screen.content.width / 2;
				this.removeEntity(this._button1);
			}
		}
		
		override public function transitionComplete():void
		{
			//Button #1: Go to the next island/episode if there is one. May be removed if there isn't a next episode.
			if(this._confirmed)
			{
				const nextIslandEvents:IslandEvents = new this.shellApi.islandEvents.nextEpisodeEvents();
				
				if(nextIslandEvents.accessible)
				{
					if(nextIslandEvents.earlyAccess)
					{
						if(this.shellApi.profileManager.active.isMember)
						{
							this.shellApi.loadFile(this.shellApi.dataPrefix + "scenes/" + nextIslandEvents.island + "/island.xml", this.nextIslandXMLLoaded);
						}
						else
						{
							this.shellApi.loadScene(Map);
						}	
					}
					else
					{
						this.shellApi.loadFile(this.shellApi.dataPrefix + "scenes/" + nextIslandEvents.island + "/island.xml", this.nextIslandXMLLoaded);
					}
				}
				else
				{
					this.shellApi.loadScene(Map);
				}
			}
			//Button #2: Go to the Map.
			else
			{
				this.shellApi.loadScene(Map);
			}
		}
		
		private function nextIslandXMLLoaded(xml:XML):void
		{
			const doorParser:DoorParser = new DoorParser();
			const doorData:DoorData = doorParser.parseDoor(xml.firstScene);
			this.shellApi.loadScene(doorData);
		}
	}
}