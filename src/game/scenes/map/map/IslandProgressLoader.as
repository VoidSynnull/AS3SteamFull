package game.scenes.map.map
{
	import engine.ShellApi;
	
	import game.util.DataUtils;
	
	import org.osflash.signals.Signal;

	public class IslandProgressLoader
	{
		private var _shellApi:ShellApi;
		
		private var _island:String = "";
		private var _numEpisodes:int = 0;
		private var _numIslands:int = 0;
		private var _islandsLoaded:int = 0;
		
		public var loaded:Signal = new Signal(IslandProgressLoader);
		public var progresses:Array = [];
		
		public function IslandProgressLoader(shellApi:ShellApi, island:String, numEpisodes:int = 0)
		{
			_shellApi = shellApi;
			_island = island;
			_numEpisodes = numEpisodes;
			_numIslands = numEpisodes;
			if(_numIslands == 0)
			{
				_numIslands = 1;
			}
		}
		
		public function destroy():void
		{
			_shellApi = null;
			_island = null;
			_numEpisodes = 0;
			_numIslands = 0;
			_islandsLoaded = 0;
			progresses.length = 0;
			loaded.removeAll();
		}
		
		public function load():void
		{
			this.loadProgressXML();
		}
		
		private function loadProgressXML():void
		{
			if(_numEpisodes == 0)
			{
				_shellApi.loadFile(_shellApi.dataPrefix + "scenes/" + _island + "/progress.xml", progressXMLLoaded);
			}
			else
			{
				_shellApi.loadFile(_shellApi.dataPrefix + "scenes/" + _island + (_islandsLoaded + 1) + "/progress.xml", progressXMLLoaded);
			}
		}
		
		private function progressXMLLoaded(progressXML:XML):void
		{
			++_islandsLoaded;
			
			if(progressXML != null)
			{
				var island:String = DataUtils.getString(progressXML.island);
				
				if(progressXML.hasOwnProperty("events"))
				{
					var eventsXML:XMLList = progressXML.events.children();
					
					var total:int = eventsXML.length();
					
					if(total > 0)
					{
						var completed:int = 0;
						
						for each(var eventXML:XML in eventsXML)
						{
							if(_shellApi.checkEvent(String(eventXML), island))
							{
								++completed;
							}
						}
						progresses.push(completed / total);
					}
				}
			}
			/*
			If processing the XML wasn't successful, then we'll have 1 less
			progress than we do islands loaded. If it fails, just add 0 progress.
			*/
			if(progresses.length < _islandsLoaded)
			{
				progresses.push(0);
			}
			
			if(_islandsLoaded < _numIslands)
			{
				this.loadProgressXML();
			}
			else
			{
				loaded.dispatch(this);
			}
		}
	}
}