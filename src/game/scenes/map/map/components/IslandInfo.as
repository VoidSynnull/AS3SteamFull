package game.scenes.map.map.components
{
	import ash.core.Component;
	
	public class IslandInfo extends Component
	{
		public var name:String = "";
		public var gameVersion:String = "AS3"; //Or AS2
		public var numEpisodes:int = 0;
		public var progresses:Array = [];
		public var page:int = 0;
		
		public function IslandInfo(name:String = "", gameVersion:String = "AS3", numEpisodes:int = 0)
		{
			this.name = name;
			this.gameVersion = gameVersion;
			this.numEpisodes = numEpisodes;
			super();
		}
	}
}