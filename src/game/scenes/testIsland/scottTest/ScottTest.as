package game.scenes.testIsland.scottTest
{
	import com.adobe.crypto.MD5;
	
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	
	import game.components.entity.collider.GravityWellCollider;
	import game.components.hit.GravityWell;
	import game.scene.template.ActionsGroup;
	import game.scene.template.PlatformerGameScene;
	import game.systems.actionChain.ActionChain;
	import game.systems.hit.GravityWellSystem;
	import game.util.EntityUtils;
	import game.util.SkinUtils;
	
	public class ScottTest extends PlatformerGameScene
	{
		public function ScottTest()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/testIsland/scottTest/";
			
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
			super.loaded();
			
			SkinUtils.setSkinPart(player, SkinUtils.ITEM, "ad_pranks_pie");
			shellApi.profileManager.updateCredits(creditsDone);
			
			//gravityWells();			
			//magnetSetup();
		}
		
		private function creditsDone():void
		{
			trace("Credits Amount: " + shellApi.profileManager.active.credits);
		}
		
		private function callAction():void
		{
			var chain:ActionChain = ActionsGroup(getGroupById(ActionsGroup.GROUP_ID)).getActionChain("attack");
			chain.execute();
		}
		
		public function magnetSetup():void
		{
			//addChildGroup(new PhotoBooth(overlayContainer, "photoBooth"));
		}
		
		private function gravityWells():void
		{
			var well:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["gravityWell"], _hitContainer);
			well.add(new GravityWell(400, 800, 20, false)).add(new Id("gravityWell"));
			
			var well2:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["gravityWell2"], _hitContainer);
			well2.add(new GravityWell(300, 900, 0, false)).add(new Id("gravityWell2"));
			
			player.add(new GravityWellCollider());
			this.addSystem(new GravityWellSystem());
		}
	}
}