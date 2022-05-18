package com.poptropica.shells.shared.steps
{
	import com.poptropica.shellSteps.shared.CreateGame;
	
	import ash.tick.FrameTickProvider;
	
	import engine.managers.FileManager;
	import engine.managers.SoundManager;
	
	import game.data.character.VariantLibrary;
	import game.data.ui.ToolTipParser;
	import game.managers.GameEventManager;
	import game.managers.IslandManagerPop;
	import game.managers.ItemManagerPop;
	import game.managers.LanguageManager;
	import game.managers.LayoutManager;
	import game.managers.SceneManager;
	import game.managers.ScreenManager;
	import game.managers.SmartFoxManager;
	import game.managers.SpecialAbilityManager;
	import game.managers.TextManager;
	import game.managers.interfaces.IIslandManager;
	import game.managers.interfaces.IItemManager;
	import game.scene.template.DoorGroupPop;
	import game.scene.template.ui.CardGroupPop;
	import game.ui.hud.Hud;
	
	public class CreateGamePop extends CreateGame
	{
		public function CreateGamePop()
		{
			super();
		}
		
		override protected function build():void
		{
			this.addManagers();
			super.createDevTools();
			built();
		}
		
		override protected function addManagers():void
		{
			var fileManager:FileManager = shellApi.fileManager;
			var screenManager:ScreenManager = shellApi.screenManager;
			var sceneManager:SceneManager = shellApi.sceneManager;
			
			// Setup standard game managers
			var layoutManager:LayoutManager = this.shellApi.addManager(new LayoutManager()) as LayoutManager;
			shellApi.injector.map(LayoutManager).toValue(layoutManager);
			
			var toolTipParser:ToolTipParser = new ToolTipParser();
			sceneManager.toolTipData = toolTipParser.parse(fileManager.getFile(fileManager.dataPrefix + "ui/toolTip.xml"));
			shellApi.injector.map(SceneManager).toValue(sceneManager);
			
			var soundManager:SoundManager = this.shellApi.addManager(new SoundManager()) as SoundManager;
			shellApi.injector.map(SoundManager).toValue(soundManager);
			
			var textManager:TextManager = new TextManager();
			textManager.parse(fileManager.getFile(fileManager.contentPrefix + "style/styles.xml"));
			this.shellApi.addManager(textManager);
			this.shellApi.addManager(new LanguageManager());
			this.shellApi.addManager(new GameEventManager());
			
			// NOTE :: Not sure what this is for, could use more comments? -bard
			this.shell._tickProvider = new FrameTickProvider(screenManager.container, MAX_FRAME_TIME);
			this.shell._tickProvider.add(shellApi.groupManager.systemManager.update);
			
			var variantLibrary:VariantLibrary = this.shellApi.addManager(new VariantLibrary()) as VariantLibrary;
			shellApi.injector.map(VariantLibrary).toValue(variantLibrary);

			shellApi.addManager(new SpecialAbilityManager());
			
			shellApi.addManager(new SmartFoxManager());
			
			if(super.shellApi.getManager(IItemManager) == null)
			{
				var itemManager:ItemManagerPop = new ItemManagerPop();
				itemManager.cardGroupClass = CardGroupPop;
				this.shellApi.addManager(itemManager, IItemManager);
			}
			
			if(super.shellApi.getManager(IIslandManager) == null)
			{
				// adding this here as when testing on flashbuilder NO islandManager is added currently...in browser or mobile modes their respective IslandManager will override this one. 
				var islandManager:IslandManagerPop = this.shellApi.addManager(new IslandManagerPop(), IIslandManager) as IslandManagerPop;
				islandManager.gameData = shellApi.sceneManager.gameData;
				islandManager.hudGroupClass = Hud;
				islandManager.doorGroupClass = DoorGroupPop;
			}
			
			this.shellApi.gameEventManager.restore(this.shellApi.profileManager.active.events);
			this.shellApi.itemManager.restoreSets(this.shellApi.profileManager.active.items);
		}
	}
}