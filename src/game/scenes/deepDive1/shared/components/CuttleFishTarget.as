package game.scenes.deepDive1.shared.components
{
	import ash.core.Component;
	import ash.core.Entity;
	
	public class CuttleFishTarget extends Component
	{
		public var occupant:Entity = null;
		// other target points that are reachable from here
		public var possibleLinks:Array;
		
		public function CuttleFishTarget(possibleLinks:Array)
		{
			this.possibleLinks = possibleLinks;
		}
		
		public function findOpening():Entity
		{
			var opening:Entity = null;
			for each (var targ:Entity in possibleLinks) 
			{
				if(!targ.get(CuttleFishTarget).occupant){
					opening = targ;
				}
			}
			return opening;
		}
	}
}