package game.scenes.mocktropica.shared {

	import game.scene.template.PlatformerGameScene;
	import game.scene.template.SceneUIGroup;
	import flash.display.Sprite;
	
	
	public class MocktropicaScene extends PlatformerGameScene 
	{
	
		public function MocktropicaScene()
		{
			super();
		}
	
		protected override function addUI(container:Sprite):void
		{
			var sceneUIGroup:SceneUIGroup = new SceneUIGroup(super.overlayContainer, container);
			sceneUIGroup.hudClass = MocktropicanHUD;
			super.addChildGroup(sceneUIGroup);
		}
	}
}
