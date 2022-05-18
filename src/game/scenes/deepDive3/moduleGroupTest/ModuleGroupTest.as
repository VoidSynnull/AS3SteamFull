package game.scenes.deepDive3.moduleGroupTest
{
	import flash.display.DisplayObjectContainer;
	
	import game.scenes.deepDive1.shared.SubScene;
	import game.scenes.deepDive3.DeepDive3Events;
	import game.scenes.deepDive3.shared.MemoryModuleGroup;
	
	public class ModuleGroupTest extends SubScene
	{
		private var moduleGroup:MemoryModuleGroup;
		private var _events3:DeepDive3Events;
		
		public function ModuleGroupTest()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/deepDive3/moduleGroupTest/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			moduleGroup = MemoryModuleGroup(addChildGroup(new MemoryModuleGroup(this,_hitContainer,_events3.STAGE_1_ACTIVE)));
			
			super.loaded();
		}
	}
}