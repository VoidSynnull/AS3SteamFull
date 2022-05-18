package game.scenes.examples.parentedAnimations
{
	import flash.display.DisplayObjectContainer;
	
	import game.scene.template.PlatformerGameScene;
	import game.scenes.arab1.shared.creators.CamelCreator;
	
	public class ParentedAnimations extends PlatformerGameScene
	{
		public function ParentedAnimations()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/examples/parentedAnimations/";
			
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
			
			setUpCamel();
		}
		
		private function setUpCamel():void
		{
			var camelCreator:CamelCreator = new CamelCreator(this, _hitContainer);
			camelCreator.create(null, player);
		}
	}
}