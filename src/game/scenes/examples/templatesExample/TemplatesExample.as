package game.scenes.examples.templatesExample
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	
	import game.components.input.Input;
	import game.managers.TemplateManager;
	import game.scene.template.PlatformerGameScene;
	import game.util.ArrayUtils;
	
	public class TemplatesExample extends PlatformerGameScene
	{
		public function TemplatesExample()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/examples/templatesExample/";
			
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
			
			var templates:XML = super.getData("templates.xml");
			
			_templateManager = new TemplateManager();
			// initialize the templateManager with the scene and the data to use for templates.  In this example templates.xml is included in the scene.xml list of data to load.
			_templateManager.init(this, templates);
			
			// a random ball is created where the user clicks.
			Input(super.shellApi.inputEntity.get(Input)).inputUp.add(makeBall);
		}
		
		private function makeBall(input:Input):void
		{
			var targetX:Number = super.shellApi.globalToScene(input.target.x, "x");
			var targetY:Number = super.shellApi.globalToScene(input.target.y, "y");
			// pick one of the templates defined in templates.xml at random.  All three share a common template as well as a specific one depending on size.
			var randomTemplateGroup:String = ArrayUtils.getRandomElement(["small_ball", "medium_ball", "large_ball"]);
			var entity:Entity = _templateManager.makeFromTemplates(randomTemplateGroup, super.hitContainer, entityLoaded);
			
			entity.add(new Spatial(targetX, targetY));
		}
		
		/**
		 * The callback passed to _templateManager.makeFromTemplates calls back from the asset load, so will provide the Entity's asset as well as the entity.
		 *  If you don't need this info you can simply specify ...args in the param list.
		 */
		private function entityLoaded(asset:MovieClip, entity:Entity):void
		{
			trace("I'm alive!");
		}
		
		private var _templateManager:TemplateManager;
	}
}