package game.scene.template
{	
	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.SpatialAddition;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.entity.collider.BitmapCollider;
	import game.components.entity.collider.WallCollider;
	import game.components.hit.BitmapHit;
	import game.components.hit.Platform;
	import game.components.hit.Wall;
	import game.components.motion.Threshold;
	import game.components.motion.WaveMotion;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.motion.SceneObjectCreator;
	import game.data.WaveMotionData;
	import game.data.scene.hit.HitData;
	import game.data.ui.ToolTipType;
	import game.managers.SmartFoxManager;
	import game.managers.interfaces.IAdManager;
	import game.scenes.carrot.smelter.systems.SmasherSystem;
	import game.scenes.deepDive2.shared.popups.PuzzleKey2Popup;
	import game.scenes.myth.labyrinth.components.ScorpionComponent;
	import game.scenes.myth.labyrinth.systems.ScorpionSystem;
	import game.scenes.time.graff.components.MovingHazard;
	import game.scenes.time.graff.systems.MovingHazardSystem;
	import game.systems.SystemPriorities;
	import game.systems.TimerSystem;
	import game.systems.motion.DestinationSystem;
	import game.systems.motion.ThresholdSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.systems.ui.NavigationArrowSystem;
	import game.systems.ui.TextDisplaySystem;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	/**
	 * A base class for all platformer scenes.  Adds all common systems and character creation shortcuts.
	 * 
	 * <listing version="3.0">
	 * Load Sequence:
	 * 
	 * 1) Load scene.xml
	 * 2) Parse scene.xml and load absolute file paths (included shared data).
	 * 3) Load all xml from the &lt;data&gt; tag of scene.xml.
	 * 4) Load all assets from the &lt;assets&gt; tag of scene.xml and camera layers.
	 * 5) Create camera, add base systems, doors, character dialog, and photos.
	 * 6) Add scene ui when characters finish loading.
	 * 7) Add scene items when ui finishes loading.
	 * </listing>
	 */ 
	public class PlatformerGameScene extends GameScene
	{
		public function PlatformerGameScene()
		{
			super();
			super.defaultCursor = ToolTipType.NAVIGATION_ARROW;
		}
		
		override public function destroy():void { super.destroy(); }
		override public function init(container:DisplayObjectContainer = null):void { super.init(container); }
		override public function load():void { super.load(); }
		
		override protected function addBaseSystems():void
		{
			super.addBaseSystems();
			
			super.addSystem(new DestinationSystem(), SystemPriorities.update);
			super.addSystem(new TextDisplaySystem(), SystemPriorities.update);
			super.addSystem(new NavigationArrowSystem(), SystemPriorities.update);
			super.addSystem(new TimerSystem(), SystemPriorities.update);
		}	
		
		override protected function addGroups():void
		{
			// AD SPECIFIC : if ad manager initialized, check scene to see if ads should be loaded
			if ( AppConfig.adsActive && _firstCall ) 
			{
				// only prep scenes for ads once, when this is first called
				_firstCall = false;
				var adManager:IAdManager = shellApi.adManager;
				adManager.prepSceneForAds( this );
				if( shellApi.adManager.checkAdScene(this, this.addGroups) )
				{
					return;
				}
			}

			//NOTE :: Do we want to force CharacterGroup creation in all Platformer scenes, seems like we shouldn't need to? - bard
			
			addUI(this.uiLayer);
			super.addGroups();
			//addAntFarm(); // ant farm - temporary	
		}
								
		protected function addUI(container:Sprite):void
		{
			// this group creates all standard scene ui like the hud, inventory and costumizer.
			super.addChildGroup(new SceneUIGroup(super.overlayContainer, container));
		}
		
		private var _firstCall:Boolean = true;
		
		override public function loaded():void
		{
			handleSceneInteractions();
			super.loaded();
		}
		private function handleSceneInteractions():void {
			var i:Number = _hitContainer.numChildren - 1;
			while (i != -1) {
				// if movie clip
				if (_hitContainer.getChildAt(i) is MovieClip) {
					var clip:MovieClip = MovieClip(_hitContainer.getChildAt(i));
					if (clip.name.indexOf("trap_smasher") != -1) {
						trace("smasher");
					}
					if (clip.name.indexOf("trap_movingHit") != -1 && clip.name.indexOf("Clip") == -1 && 
						clip.name.indexOf("Left") == -1 && clip.name.indexOf("Right") == -1) {
						trace("moving hit found");
						if(super.getSystem(ThresholdSystem) == null) {
							super.addSystem( new ThresholdSystem(), SystemPriorities.update );	
						}
						if(super.getSystem(WaveMotionSystem) == null) {
							super.addSystem( new WaveMotionSystem() );
						}
						
						setupMovingHit(clip.name);
					}
					if (clip.name.indexOf("trap_door") != -1 && clip.name.indexOf("Clip") == -1) {
						trace("trap door");
						var number:String = clip.name.substr(9,1);
						var door:Entity = EntityUtils.createSpatialEntity(this,clip);
						var doorAnimation:Entity = TimelineUtils.convertClip(_hitContainer["trap_door"+number+"Clip"],this,null,null,false);
						var timeline:Timeline = doorAnimation.get( Timeline );
						timeline.handleLabel( "removeDoor", Command.create( removeDoor, number ), false );
						//var _sceneObjectCreator:SceneObjectCreator = new SceneObjectCreator();
						//var door:Entity = _sceneObjectCreator.createBox(clip,0,super.hitContainer,clip.x, clip.y);
						door.add( new Platform() );
						door.add(new Id(clip.name));
						door.add(new Wall());
						door.add(new WallCollider());
						
						door.add(new HitData());
						
						door.add(new BitmapCollider());
						door.add(new BitmapHit());
						
						
					}
					if (clip.name.indexOf("trap_button") != -1) {
						trace("trap button");
						var index:String = clip.name.substr(11,1);
						var trapButtonEntity:Entity = EntityUtils.createSpatialEntity(this, clip);
					  	TimelineUtils.convertClip(clip,this, trapButtonEntity);
						
						var sceneInt:SceneInteraction = new SceneInteraction();
						InteractionCreator.addToEntity(trapButtonEntity, ["click"]);
						sceneInt.reached.addOnce(Command.create(openTrapDoor,index));
						trapButtonEntity.add(sceneInt);
						
					}
				}
				i--;
			}
		}
		///// AUTOMATIC SCENE STUFF /////
		private function openTrapDoor(player:Entity, clickedEntity:Entity, index:String):void {
			trace("remove door " + index);
			var door:Entity = getEntityById("trap_door"+index+"Clip");
			//Timeline(door.get(Timeline)).handleLabel( "removeDoor", Command.create( removeDoor, index) );//, "triggerLoop" ));
			Timeline(door.get(Timeline)).play();
		}
		private function removeDoor(index:String):void
		{
			getEntityById("trap_door"+index+"Clip").get(Timeline).gotoAndStop("removeDoor");
			var wall:Entity = getEntityById("trap_door"+index);
			wall.remove(Wall);
			wall.remove(HitData);
			wall.remove(Platform);
			wall.remove(BitmapCollider);
			wall.remove(BitmapHit);
			EntityUtils.visible(wall, false);
		}
		private function setupMovingHit(clipName:String):void
		{
			MovingHazardSystem(addSystem(new MovingHazardSystem(true),SystemPriorities.update));			
			var movingHit:Entity = super.getEntityById( clipName );	
			var movingHaz:MovingHazard = new MovingHazard();
			movingHaz.visible = super.getEntityById( clipName + "Clip" );		
			movingHaz.leftThreshHold = MovieClip(_hitContainer[clipName + "Left"]).x;	
			movingHaz.rightThreshHold = MovieClip(_hitContainer[clipName + "Right"]).x;	
			movingHit.add(new Motion());
			movingHit.get(Motion).velocity = new Point( 110, 0 );
			movingHit.add(new Threshold( "x", "<" ));
			movingHit.add(movingHaz);
			MotionUtils.addWaveMotion(movingHit,new WaveMotionData( "y", 1.5, 50 ),this);

		}
		
		///// TEMP FOR MULTIPLAYER TESTING /////
		
		private function addAntFarm():void{
			if(SmartFoxManager.TEST_MODE_ON && shellApi.smartFox.currentZone == AppConfig.multiplayerZone && shellApi.sceneName != "Starcade"){
				
				if(AppConfig.debug){
					trace("   ---------------------------------");
					trace("   [ ...   Add AntGroup At 1   ... ]");
					trace("   ---------------------------------");
				}
				
				// update user's location on server
				shellApi.smartFoxManager.updateLocation();
				// add antFarm group
				super.addChildGroup(new SFAntGroup());
			} else {
				// wait for login
				shellApi.smartFoxManager.loggedIn.addOnce(enableAntFarmOnLogin);
			}
		}
		
		private function enableAntFarmOnLogin():void{
			if(SmartFoxManager.TEST_MODE_ON && shellApi.sceneName != "Starcade"){
				
				if(AppConfig.debug){
					trace("   ---------------------------------");
					trace("   [ ...   Add AntGroup At 2   ... ]");
					trace("   ---------------------------------");
				}
				
				// update user's location on server
				shellApi.smartFoxManager.updateLocation();
				// add antFarm group
				super.addChildGroup(new SFAntGroup());
			}
		}
	}
}
