package game.ui.card
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import engine.ShellApi;
	
	import game.data.ui.card.CardRadioButtonData;

	public class EpisodicIslandData
	{
		public var island:String;
		public var completed:Boolean;
		
		public function EpisodicIslandData(island:String, completed:Boolean)
		{
			this.island = island;
			this.completed = completed;
		}
		
		public static function generateIslandData(shellApi:ShellApi, island:String, episodes:uint):Vector.<EpisodicIslandData>
		{
			var hasMedal:Boolean;
			var items:Array;
			var radioButtonData:CardRadioButtonData;
			var value:String;
			
			var islandsCompleted:Vector.<EpisodicIslandData> = new Vector.<EpisodicIslandData>();
			
			for(var i:int = 1; i <= episodes; i++)
			{
				hasMedal = false;
				value = island + i;
				
				items = shellApi.profileManager.active.items[value];
				
				if( items != null )
				{					
					if(items.indexOf( MEDAL + value) != -1 )
					{
						hasMedal = true;
					}
				}

				trace("EpisodicIslandData :: has medalion for " + value + ": " + hasMedal)
				islandsCompleted.push( new EpisodicIslandData(value, hasMedal));
			}
			return islandsCompleted;
		}
		
		// each piece of the content should be labeled with respective islandName
		// and medals are all called "medal_islandName"
		// if there is a seperate asset for when an island is not completed
		// add "_incomplete" to the end of the name for the default view
		// add "_icon" to icons you want to include (not required)
		// add "hairBoy" or "hairGirl" if it is a head piece that needs to include hair
		
		public static function configureContent(content:DisplayObjectContainer, islandData:Vector.<EpisodicIslandData>, isMale:Boolean = true):void
		{
			var data:EpisodicIslandData;
			var clip:MovieClip;
			var icon:MovieClip;
			
			for(var i:int = 0; i < islandData.length; i++)
			{
				data = islandData[i];
				
				if(data.completed)
				{
					clip = content[data.island + INCOMPLETE];
					if(clip != null)
						clip.visible = false;
				}
				else
				{
					clip = content[data.island];
					clip.visible = false;
					icon = content[data.island + ICON];
					if(icon != null)
						icon.visible = false;
				}
			}
			
			clip = content[HAIR+GIRL];
			if(clip != null)
			{
				if(isMale)
					clip.visible = false;
				else
					content[HAIR+BOY].visible = false;
			}
		}
		
		private static const MEDAL:String = "medal_";
		private static const INCOMPLETE:String = "_incomplete";
		private static const ICON:String	= "_icon";
		
		private static const HAIR:String = "hair";
		private static const BOY:String = "Boy";
		private static const GIRL:String = "Girl";
	}
}