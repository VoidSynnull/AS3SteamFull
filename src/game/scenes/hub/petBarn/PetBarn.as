package game.scenes.hub.petBarn
{
	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.components.ui.ToolTipActive;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.display.BitmapWrapper;
	import game.data.specialAbility.SpecialAbilityData;
	import game.data.ui.ToolTipType;
	import game.managers.ItemManager;
	import game.managers.ScreenManager;
	import game.nodes.entity.character.NpcNode;
	import game.scene.template.CharacterGroup;
	import game.scene.template.GameScene;
	import game.scene.template.PlatformerGameScene;
	import game.scene.template.ui.CardGroup;
	import game.scenes.hub.petBarn.PetColorizer;
	import game.ui.elements.ConfirmationDialogBox;
	import game.ui.hud.Hud;
	import game.ui.hud.HudPopBrowser;
	import game.ui.popup.ItemStorePopup;
	import game.ui.saveGame.SaveGamePopup;
	import game.util.DisplayUtils;
	import game.util.PlatformUtils;

	public class PetBarn extends PlatformerGameScene
	{
		private var pet:String;
		private var petID:String;
		private var ui:MovieClip;
		
		private var _loadingCardWrapper:BitmapWrapper;
		private var _loadingWheelWrapper:BitmapWrapper;
		
		private var _platformFilesLoaded:Boolean = false;

		// buttons
		private var inventoryButton:Entity;
		private var storeButton:Entity;
		private var saveStoreButton:Entity;
		private var closeSaveStoreButton:Entity;
		private var steamPets:Array;
		public function PetBarn()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/hub/petbarn/";
			super.init(container);
			steamPets = new Array();
			var card:Object = new Object();
			card.id = "6000";
			card.mem_only = false;
			card.name = "Pet Kitten";
			card.price = 0;
			steamPets.push(card);
			card = new Object();
			card.id = "6001";
			card.mem_only = false;
			card.name = "Pet Puppy";
			card.price = 0;
			steamPets.push(card);
			card = new Object();
			card.id = "6002";
			card.mem_only = false;
			card.name = "Pet Goat";
			card.price = 0;
			steamPets.push(card);
			card = new Object();
			card.id = "6003";
			card.mem_only = false;
			card.name = "Pet Bunny";
			card.price = 0;
			steamPets.push(card);
			card = new Object();
			card.id = "6004";
			card.mem_only = false;
			card.name = "Pet Lizard";
			card.price = 0;
			steamPets.push(card);
			card = new Object();
			card.id = "6005";
			card.mem_only = false;
			card.name = "Pet Husky";
			card.price = 0;
			steamPets.push(card);
			card = new Object();
			card.id = "6006";
			card.mem_only = false;
			card.name = "Pet Pony";
			card.price = 0;
			steamPets.push(card);
			
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
			super.shellApi.loadFiles( [ super.shellApi.assetPrefix + "ui/general/load_wheel.swf", super.shellApi.assetPrefix + "items/ui/background_loading.swf"], loadedInitAssets);
		}

		override protected function addGroups():void
		{
			if( !_platformFilesLoaded )
			{
				var filePrefix:String = ( PlatformUtils.isMobileOS ) ? "mobile/" : "browser/";
				super.sceneDataManager.loadSceneConfiguration(GameScene.SCENE_FILE_NAME, super.groupPrefix + filePrefix, loadPlatformSpecificMerge);
			}
			else
			{
				// possible for this to get called again based on how PlatformerGameScene.addGroups works, need to maintain flag so this does loop
				super.addGroups();
			}
		}
		
		private function loadPlatformSpecificMerge(files:Array):void
		{
			_platformFilesLoaded = true;
			var filePrefix:String = ( PlatformUtils.isMobileOS ) ? "mobile/" : "browser/";
			// merge all the scene files from the appropriate folder using the default merge process 
			super.sceneDataManager.mergeSceneFiles(files, super.groupPrefix + filePrefix, super.groupPrefix);
			super.addGroups();
		}

		private function loadedInitAssets():void
		{
			var cardScale:Number = 1;
			// store references to loading assets
			var loadWheel:MovieClip = shellApi.getFile( shellApi.assetPrefix + "ui/general/load_wheel.swf" ) as MovieClip;
			_loadingWheelWrapper = DisplayUtils.convertToBitmapSprite( loadWheel, loadWheel.getBounds(loadWheel), cardScale, false );
			var loadingCard:MovieClip = shellApi.getFile( shellApi.assetPrefix + "items/ui/background_loading.swf" ) as MovieClip;
			_loadingCardWrapper = DisplayUtils.convertToBitmapSprite( loadingCard, CardGroup.CARD_BOUNDS, cardScale );
		}

		// all assets ready
		override public function loaded():void
		{
			super.loaded();

			// setup colorizer interaction
			var entity:Entity = this.getEntityById("colorizerInteraction");
			var sceneInteraction:SceneInteraction = entity.get(SceneInteraction);
			sceneInteraction.reached.add(this.onColorizerReached);
			
			// listen for hud closing and opening
			Hud(this.getGroupById(Hud.GROUP_ID)).openingHud.add(hudOpened);

			// load UI
			shellApi.loadFile(shellApi.assetPrefix + "ui/petBarn/ui.swf", uiLoaded);

			// get pet cards from list of all store cards
			var petList:Array = [];
			for each (var card:Object in steamPets)
			{

					var cardobj:Object = {};
					// convert "Pet_Name" to "name"
					cardobj.name = card.name.substr(4).toLowerCase();
					cardobj.id = card.id;
					cardobj.mem_only = card.mem_only;
					petList.push(cardobj);
				

			}
			
			// prepare pets in scene
			// process pet interactions
			var nonMembersBlocked:Boolean = false;
			var nodeList:NodeList = systemManager.getNodeList(NpcNode);
			var memberPetIds:Array = [];
			//starts off as a list of all pets
			for(var node:NpcNode = nodeList.head; node; node = node.next)
			{
				memberPetIds.push(node.entity.get(Id).id);
			}
			
			for (var i:int = 0; i != petList.length; i++)
			{
				// get pet name
				var pet:String = petList[i].name;
				
				// get interaction and add function for when player reaches clip
				entity = this.getEntityById(pet + "Interaction");
				if (entity != null)
				{
					
					sceneInteraction = entity.get(SceneInteraction);
					sceneInteraction.reached.add(Command.create(selectPet, pet, petList[i].id, petList[i].mem_only));
					
					// move clip above pets but just behind player
					var display:DisplayObject = entity.get(Display).displayObject;
					display.parent.setChildIndex(display, display.parent.numChildren - 2);
				}
			}

		}
		
		private function removePetIdsWithKeyword(memberPetIds:Array, pet:String):Array
		{
			var index:int = 0;
			var petId:String;
			while(index >= 0)
			{
				index = -1;
				for(var i:int = 0; i < memberPetIds.length; i++)
				{
					petId = memberPetIds[i];
					if(petId.indexOf(pet) > -1)
						index = i;
				}
				if(index > -1)
					memberPetIds.splice(index, 1);
			}
			return memberPetIds;
		}
		
		// setup UI
		private function uiLoaded(ui:MovieClip):void
		{
			// add ui to overlay
			this.ui = MovieClip(this.overlayContainer.addChild(ui));
			
			// adjust if screen is more square
			if (shellApi.camera.viewportWidth / shellApi.camera.viewportHeight < ScreenManager.GAME_WIDTH / ScreenManager.GAME_HEIGHT)
			{
				// move ui down to bottom of screen area
				ui.y = shellApi.camera.viewportHeight - ScreenManager.GAME_HEIGHT;
				// scale panel to fit height
				//ui.scaleX = ui.scaleY = shellApi.camera.viewportHeight / ScreenManager.GAME_HEIGHT;
			}
			
			// inventory button
			inventoryButton = ButtonCreator.createButtonEntity( ui.inventoryButton, this, openInventory, null, null, ToolTipType.CLICK);
			
			// store button
			storeButton = ButtonCreator.createButtonEntity( ui.storeButton, this, openStore, null, null, ToolTipType.CLICK);
			
			// if guest, then dim
			if (shellApi.profileManager.active.isGuest)
			{
				storeButton.get(Display).alpha = 0.5;
			}
			storeButton.get(Display).alpha = 0;			
			// save panel for store button
			ui.storePanel.visible = false;
			saveStoreButton = ButtonCreator.createButtonEntity( ui.storePanel.saveButton, this, saveGame, null, null, ToolTipType.CLICK);
			closeSaveStoreButton = ButtonCreator.createButtonEntity( ui.storePanel.closeButton, this, Command.create(showSaveStorePanel,false), null, null, ToolTipType.CLICK);
		}
		
		// when pet interaction reached
		private function selectPet(player:Entity, entity:Entity, pet:String, id:String, membersOnly:Boolean):void
		{
			var dialogBox:ConfirmationDialogBox;
			if (shellApi.checkHasItem(id, CardGroup.PETS))
			{
				dialogBox = this.addChildGroup(new ConfirmationDialogBox(1, "You already have a " + pet + "!")) as ConfirmationDialogBox;
			}
			else
			{
				this.pet = pet;
				this.petID = id;
				dialogBox = this.addChildGroup(new ConfirmationDialogBox(2, "Do you want a " + pet + "?", confirmPet)) as ConfirmationDialogBox;
			}
			dialogBox.darkenBackground 	= true;
			dialogBox.pauseParent 		= true;
			dialogBox.init(this.overlayContainer);
		}
		
		// when confirming pet from dialog
		private function confirmPet():void
		{
			// tracking
			shellApi.track("GotPet", pet, null, "Pets");
			
			// put pet in inventory
			shellApi.getItem(petID, CardGroup.PETS);
			
			// load follower
			shellApi.specialAbilityManager.addSpecialAbilityById(shellApi.player, "pets/pop_follower_" + pet, false);
			
			// wait for follower to complete loading
			var charGroup:CharacterGroup = this.getGroupById("characterGroup") as CharacterGroup;
			charGroup.addCompleteListener(Command.create(onColorizerReached), true);
		}
		
		// when colorized reached or when follower loaded
		private function onColorizerReached(player:Entity = null, entity:Entity = null):void
		{
			// get special ability data
			var data:SpecialAbilityData = shellApi.specialAbilityManager.getAbility("pets/pop_follower");
			if (data == null)
			{
				// show error dialog
				var dialogBox:ConfirmationDialogBox = this.addChildGroup(new ConfirmationDialogBox(1, "You need to have a pet to use this feature!")) as ConfirmationDialogBox;
				dialogBox.darkenBackground 	= true;
				dialogBox.pauseParent 		= true;
				dialogBox.init(this.overlayContainer);
			}
			// if data exists, then show pet colorizer
			else
			{
				this.addChildGroup(new PetColorizer(this.overlayContainer));
			}
		}
		
		// open pet inventory
		private function openInventory(btnEntity:Entity):void
		{
			var hud:Hud = Hud(this.getGroupById(Hud.GROUP_ID));
			hud.openPetInventory();
			// hide buttons
			hudOpened(true);
		}
		
		// when hud closed then show buttons
		private function hudOpened(state:Boolean):void
		{
			showButton(inventoryButton, !state);
			showButton(storeButton, !state);
		}
		
		// open pet store
		private function openStore(btnEntity:Entity):void
		{
			if (btnEntity.get(Display).alpha == 0.5)
			{
				// show save panel
				showSaveStorePanel(null, true);
			}
			else
			{
				// reset button to first frame (fixes lingering text rollover)
				btnEntity.get(Timeline).gotoAndStop(0);
				// load store popup
				var popup:ItemStorePopup = this.addChildGroup(new ItemStorePopup(this, true, _loadingWheelWrapper, _loadingCardWrapper)) as ItemStorePopup;
				popup.init( shellApi.sceneManager.currentScene.overlayContainer );
			}
		}
		
		// save game by registering
		private function saveGame(btnEntity:Entity):void
		{
			addChildGroup(new SaveGamePopup(shellApi.currentScene.overlayContainer)) as SaveGamePopup;
		}
		
		// when user registration succeeds
		override public function registrationSuccess():void
		{
			// hide panel
			showSaveStorePanel(null, false);
			// undim store button
			storeButton.get(Display).alpha = 1;
		}

		// show/hide save store panel
		private function showSaveStorePanel(btnEntity:Entity, state:Boolean):void
		{
			ui.storePanel.visible = state;
			showButton(saveStoreButton, state);
			showButton(closeSaveStoreButton, state);
		}
		
		// show/hide button
		private function showButton(btnEntity:Entity, state:Boolean):void
		{
			// set visibility
			btnEntity.get(Display).visible = state;
			
			// set sleep
			Sleep(btnEntity.get(Sleep)).sleeping = !state;
			
			// enable/disable tooltip
			if (state)
			{
				if (!btnEntity.has(ToolTipActive))
				{
					ToolTipCreator.addToEntity(btnEntity, ToolTipType.CLICK);
				}
			}
			else
			{
				ToolTipCreator.removeFromEntity(btnEntity);
			}
		}
	}
}