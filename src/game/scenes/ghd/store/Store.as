package game.scenes.ghd.store
{
	import flash.display.DisplayObjectContainer;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.SpatialAddition;
	
	import game.components.motion.WaveMotion;
	import game.components.scene.SceneInteraction;
	import game.data.WaveMotionData;
	import game.scene.template.CharacterGroup;
	import game.scenes.ghd.GalacticHotDogScene;
	import game.scenes.ghd.store.popups.BioPopup;
	import game.systems.motion.WaveMotionSystem;
	import game.util.TimelineUtils;
	
	public class Store extends GalacticHotDogScene
	{
		public var characters:Array = ["cosmoe", "humphree", "dagger", "fred"];
		
		public function Store()
		{
			super();
		}
		
		override public function init( container:DisplayObjectContainer = null ):void
		{			
			super.groupPrefix = "scenes/ghd/store/";
			
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
			
			this.addSystem(new WaveMotionSystem());
			
			setupMannequins();
			setupCharacterProjections();
			setupProjections();
			setupBioCharacters();
			setupEpisodes();
			setupBook();
			setupWebsite();
			setupFan();
		}
		
		private function setupMannequins():void
		{
			var characterGroup:CharacterGroup = this.getGroupById(CharacterGroup.GROUP_ID) as CharacterGroup;
			
			//Subtract 1 to exclude FRED from for loop.
			for(var index:int = 0; index < characters.length - 1; ++index)
			{
				var mannequin:Entity = this.getEntityById(characters[index]);
				characterGroup.configureCostumizerMannequin(mannequin);
			}
		}
		
		private function setupFan():void
		{
			TimelineUtils.convertClip(this._hitContainer["fan"], this);
		}
		
		private function setupCharacterProjections():void
		{
			for(var index:int = characters.length - 1; index > -1; --index)
			{
				TimelineUtils.convertClip(this._hitContainer[characters[index] + "Hologram"], this);
			}
		}
		
		private function setupProjections():void
		{
			for(var index:int = 1; index <= 6; ++index)
			{
				TimelineUtils.convertClip(this._hitContainer["projection" + index], this);
			}
		}
		
		private function setupBook():void
		{
			var entity:Entity = this.getEntityById("bookInteraction");
			
			Display(entity.get(Display)).isStatic = false;
			
			entity.add(new SpatialAddition());
			
			var waveMotion:WaveMotion = new WaveMotion();
			waveMotion.add(new WaveMotionData("y", 10, 1, "sin", 0, true));
			entity.add(waveMotion);
			
			var sceneInteraction:SceneInteraction = entity.get(SceneInteraction);
			sceneInteraction.approach = false;
			sceneInteraction.triggered.add(this.onBookClicked);
		}
		
		private function onBookClicked(player:Entity, entity:Entity):void
		{
			this.shellApi.track("ClickedBook", "GHDbook1cover");
			navigateToURL(new URLRequest("https://www.amazon.com/gp/product/1481424947/ref=as_li_qf_sp_asin_il_tl?ie=UTF8&camp=1789&creative=9325&creativeASIN=1481424947&linkCode=as2&tag=poptropica-20&linkId=WSRJ6B2PONL5FQK4"));
		}
		
		private function setupWebsite():void
		{
			var entity:Entity = this.getEntityById("websiteInteraction");
			
			Display(entity.get(Display)).isStatic = false;
			
			entity.add(new SpatialAddition());
			
			var waveMotion:WaveMotion = new WaveMotion();
			waveMotion.add(new WaveMotionData("y", 10, 1, "sin", Math.PI, true));
			entity.add(waveMotion);
			
			var sceneInteraction:SceneInteraction = entity.get(SceneInteraction);
			sceneInteraction.approach = false;
			sceneInteraction.triggered.add(this.onWebsiteClicked);
		}
		
		private function onWebsiteClicked(player:Entity, entity:Entity):void
		{
			navigateToURL(new URLRequest("https://www.funbrain.com/galactichotdogs/?utm_source=GHD_img_VisitReadAll_GHDstore-pop&utm_medium=Display&utm_campaign=GHD"));
		}
		
		private function setupEpisodes():void
		{
			for(var index:int = 1; index <= 2; ++index)
			{
				var entity:Entity = this.getEntityById("episode" + index + "Interaction");
				var sceneInteraction:SceneInteraction = entity.get(SceneInteraction);
				sceneInteraction.approach = false;
				sceneInteraction.triggered.add(this.onEpisodeClicked);
			}
		}
		
		private function onEpisodeClicked(player:Entity, entity:Entity):void
		{
			var id:String = Id(entity.get(Id)).id;
			id = id.replace("Interaction", "");
			
			if(id == "episode1")
			{
				navigateToURL(new URLRequest("https://www.funbrain.com/galactichotdogs/index.html?start_reading=ep01&utm_source=GHD_img_Episode1_GHDstore-pop&utm_medium=Display&utm_campaign=GHD"));
			}
			else if(id == "episode2")
			{
				navigateToURL(new URLRequest("https://www.funbrain.com/galactichotdogs/index.html?start_reading=ep02&utm_source=GHD_img_Episode2_GHDstore-pop&utm_medium=Display&utm_campaign=GHD"));
			}
		}
		
		private function setupBioCharacters():void
		{
			for(var index:int = characters.length - 1; index > -1; --index)
			{
				var character:Entity = this.getEntityById(characters[index] + "Interaction");
				var sceneInteraction:SceneInteraction = character.get(SceneInteraction);
				sceneInteraction.approach = false;
				sceneInteraction.triggered.add(onCharacterBioClicked);
			}
		}
		
		private function onCharacterBioClicked(player:Entity, entity:Entity):void
		{
			var id:String = Id(entity.get(Id)).id;
			id = id.replace("Interaction", "");
			
			var bioPopup:BioPopup = new BioPopup(this.overlayContainer);
			bioPopup.frame = id;
			this.addChildGroup(bioPopup);
		}
	}
}