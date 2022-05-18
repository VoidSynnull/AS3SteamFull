package game.scenes.con1.roofRace.NavigationSmart
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import game.scene.template.PlatformerGameScene;

	public class SmartNavUtils
	{
		public function SmartNavUtils()
		{
			
		}
		
		public static function addSmartNavToChar(scene:PlatformerGameScene,char:Entity):void
		{	
			var smartNav:NavigationSmartSystem = scene.getSystem(NavigationSmartSystem) as NavigationSmartSystem;
			
			if(smartNav == null)
				scene.addSystem(new NavigationSmartSystem());
			
			char.add(new NavigationSmart());
		}
		
		public static function createPath(container:DisplayObjectContainer, debug:Boolean = false):Vector.<Point>
		{
			var path:Vector.<Point> = new Vector.<Point>();
			var nodeNumber:uint = 0;
			var pathNode:DisplayObjectContainer = container[PATH+nodeNumber];
			//not sure if they start on 1 or 0
			if(pathNode == null)
			{
				nodeNumber = 1;
				pathNode =  container[PATH+nodeNumber];
			}
			while(pathNode != null)
			{
				path.push(new Point(pathNode.x, pathNode.y));
				++nodeNumber;
				if(!debug)
					container.removeChild(pathNode);
				pathNode = container[PATH+nodeNumber];
			}
			return path;
		}
		
		public static const PATH:String = "path";
	}
}