package game.scenes.mocktropica.megaFightingBots.components
{
	import flash.display.DisplayObject;
	import flash.geom.Point;
	
	import ash.core.Component;
	
	public class ArenaControl extends Component
	{
		public function ArenaControl($gridTarg:DisplayObject):void{
			gridTarg = $gridTarg;
		}
		
		public var clickIndexPoint:Point;
		public var gridTarg:DisplayObject; // grid target graphic
	}
}