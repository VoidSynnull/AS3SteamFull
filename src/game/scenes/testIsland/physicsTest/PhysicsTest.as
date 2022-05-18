package game.scenes.testIsland.physicsTest
{
	import flash.display.DisplayObjectContainer;
	
	import game.scene.template.PlatformerGameScene;
	
	public class PhysicsTest extends PlatformerGameScene
	{
		public function PhysicsTest()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/testIsland/physicsTest/";
			
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
			//SceneUtil.delay(this, 1, Command.create(addChildGroup, new PhotoBooth( overlayContainer, "photoBooth")));
			//addChildGroup(new PhotoBooth(overlayContainer, "halloween2015"));	//halloween2015
			
			//addChildGroup(new ScreenCapture(overlayContainer, groupContainer));
			
			super.loaded();
		}
	}
}