package game.scenes.custom.questInterior
{
	import flash.display.MovieClip;
	
	import engine.group.DisplayGroup;
	
	import game.managers.ads.AdManager;
	import game.scene.template.ads.AdInteriorScene;
	import game.systems.SystemPriorities;
	import game.systems.entity.character.part.CreepyEyesSystem;
	import game.systems.entity.character.part.SyncBounceSystem;
	
	public class QuestInterior extends AdInteriorScene
	{
		private var _HUD:MovieClip;
		
		public function QuestInterior()
		{
			super();
		}
		
		/**
		 * All assets loaded 
		 */
		override public function loaded():void
		{
			// get return to interior flag
			// this needs to happen before "initScene" trigger so Win and Return events can be processed
			_returnToInterior = AdManager(super.shellApi.adManager).returnToInterior;	
			
			// look for HUD
			if (hitContainer["HUD"] != null)
			{
				_HUD = MovieClip(DisplayGroup(this).container.addChild(hitContainer["HUD"]));
				_HUD.x = -this.shellApi.camera.viewport.width/2/this.container.scaleX;
				_HUD.y = -this.shellApi.camera.viewport.height/2/this.container.scaleY;
			}
			
			super.loaded();
		}
		
		override protected function addBaseSystems():void
		{
			super.addBaseSystems();		
			// for Wrinkle in Time
			super.addSystem(new CreepyEyesSystem(), SystemPriorities.update);
			super.addSystem(new SyncBounceSystem(), SystemPriorities.preRender);
		}
	}
}

