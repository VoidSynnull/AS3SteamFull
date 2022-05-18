package game.scenes.mocktropica.chasm{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.group.Group;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.motion.MotionTarget;
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.components.entity.character.Talk;
	import game.components.hit.BitmapHit;
	import game.components.hit.Zone;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.scenes.mocktropica.MocktropicaEvents;
	import game.particles.emitter.Rain;
	import game.scene.template.CharacterGroup;
	import game.scenes.mocktropica.shared.MocktropicaScene;
	import game.scenes.mocktropica.shared.NarfCreator;
	import game.scenes.mocktropica.shared.components.Narf;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	import org.flintparticles.common.counters.Steady;
	import org.osflash.signals.Signal;
	
	public class Chasm extends MocktropicaScene
	{
		public function Chasm()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/mocktropica/chasm/";
			
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
			setupNPCs();
			setupClickables();
			
			_events = super.events as MocktropicaEvents;
			var int2:Entity = super.getEntityById("interactive2");
			_narfEyes  = MovieClip(int2.get(Display).displayObject.getChildByName("narfEyes"));
			_narfEyes.alpha = 0; // hide until needed
			
			// If it should be raining turn the rain effect on
			if(super.shellApi.checkEvent(_events.SET_RAIN))
			{
				var rain:Rain = new Rain();
				rain.init(new Steady(50), new Rectangle(0, 0, this.shellApi.viewportWidth, this.shellApi.viewportHeight), 2);
				EmitterCreator.createSceneWide(this, rain);
			}
			
			if(!super.shellApi.checkEvent(_events.MAINSTREET_FINISHED))
			{
				super.removeEntity(_safetyInspector);
			}
			
			if(super.shellApi.checkEvent(_events.DEFEATED_BOSS)){
				super.removeEntity(_safetyInspector);
			}
			
			if(!super.shellApi.checkEvent(_events.BOY_LEFT_MAIN_STREET_CHASM))
			{
				super.removeEntity(_boy);
				setupWallZone();
			}
			else
			{
				// boy has left main street for the chasm
				// if the player hasn't made the narf wall yet, setup the wall and remove the pet floor
				if(!super.shellApi.checkEvent(_events.NARF_WALL_COMPLETE))
				{
					petFloor(false);
					setupWallZone();					
					_boy.get(Dialog).sayCurrent();
					loadPets();
				}
				else
				{
					moveNarfWall(true);
				}
			}
			
			
		}
		
		private function setupClickables():void
		{
			// setup clickable interactives in scene
			_dangerSign = ButtonCreator.createButtonEntity(this._hitContainer["dangerSign"], this, onDangerSign);
			TimelineUtils.convertClip(this._hitContainer["dangerSign"], this, _dangerSign, null, false);
			
			_inspectorSign = ButtonCreator.createButtonEntity(this._hitContainer["inspectorSign"], this, onInspectorSign);
			TimelineUtils.convertClip(this._hitContainer["inspectorSign"], this, _inspectorSign, null, false);
			
			_balloon2 = ButtonCreator.createButtonEntity(this._hitContainer["balloon2"], this, onBalloon2);
			TimelineUtils.convertClip(this._hitContainer["balloon2"], this, _balloon2, null, false);
		}
		
		private function setupWallZone():void
		{	
			// have zone nearby wall to have npc tell you "halt!"
			var zoneHitEntity:Entity = super.getEntityById("zoneHalt");
			_cliffZone = zoneHitEntity.get(Zone);
			
			_cliffZone.entered.add(enterZone);
			_cliffZone.shapeHit = false;
			_cliffZone.pointHit = true;
		}
		
		private function enterZone(zoneId:String, characterId:String):void
		{
			if(!super.shellApi.checkEvent(_events.MAINSTREET_FINISHED))
			{
				Dialog(super.player.get(Dialog)).sayById("cannotCross");
			}
			else if(super.shellApi.checkEvent(_events.SPOKE_WITH_SAFETY_INSPECTOR_CHASM))
			{
				Dialog(_safetyInspector.get(Dialog)).sayCurrent();
			}
			else
			{
				Dialog(_safetyInspector.get(Dialog)).sayById("halt");
			}
			
			// move character to safe point
			CharUtils.moveToTarget(super.player, 1752, 1128, false, charSafe);
			
			// freeze controls
			SceneUtil.lockInput(this, true);
		}
		
		private function charSafe($entity:Entity):void
		{
			// unlock input
			SceneUtil.lockInput(this, false);
			
			// have inspector face char
			if(_safetyInspector.has(Spatial)) CharUtils.setDirection(_safetyInspector, true);
		}
		
		private function onBalloon2($entity:Entity):void
		{
			// change balloon look
			Display(_balloon2.get(Display)).displayObject["balloon"].gotoAndStop(2);
		}
		
		private function onInspectorSign($entity:Entity):void
		{
			// play clip to reveal "lawsuit..."
			Timeline($entity.get(Timeline)).gotoAndPlay(2);
		}
		
		private function onDangerSign($entity:Entity):void
		{
			// have the sign go to next frame to change 
			if(MovieClip(Display($entity.get(Display)).displayObject).currentFrame < MovieClip(Display($entity.get(Display)).displayObject).totalFrames){
				Timeline($entity.get(Timeline)).gotoAndStop(Timeline($entity.get(Timeline)).currentIndex + 1); 
			} else {
				Timeline($entity.get(Timeline)).gotoAndStop(0);
			}
		}
		
		private function setupNPCs():void
		{
			_safetyInspector = this.getEntityById("npc");
			_boy = this.getEntityById("boy");
		}
		
		private function loadPets():void
		{
			_narfCreator = new NarfCreator(this, super.getGroupById("characterGroup") as CharacterGroup, this._hitContainer);
			
			_narf = new Narf();
			this.player.add(_narf);
			_narf.targetChanged.add(curdLanded);
			
			_pets = new Vector.<Entity>();
			for(var i:uint = 0; i < 12; i++)
			{
				_narfCreator.create(_boy, narfLoaded);
			}
		}
		
		private function narfLoaded(entity:Entity):void
		{
			_pets.push(entity);
			this._hitContainer.setChildIndex(Display(this.player.get(Display)).displayObject, this._hitContainer.numChildren - 1);
			FSMControl(entity.get(FSMControl)).stateChange = new Signal();
			FSMControl(entity.get(FSMControl)).stateChange.add(petStateChange);
		}
		
		private function petStateChange(type:String, entity:Entity):void
		{
			if(type == "eat")
			{
				Narf(entity.get(Narf)).petChew.addOnce(petChew);
				for each(var pet:Entity in _pets)
				{
					if(pet != entity)
					{
						Narf(pet.get(Narf)).targetCurd = false;
					}
				}
			}
		}
		
		private function petChew():void
		{
			super.removeEntity(_currentCurd);
			for each(var pet:Entity in _pets)
			{
				Narf(pet.get(Narf)).targetCurd = false;
				MotionTarget(pet.get(MotionTarget)).targetSpatial = _boy.get(Spatial);
			}
		}
		
		private function curdLanded(spatial:Spatial, curd:Entity):void
		{
			_currentCurd = curd;
			var moreNarfs:Boolean = false;
			for each(var entity:Entity in _pets)
			{
				if(spatial != null)
				{
					if(spatial.x < 1600)
					{
						_narf.targetChanged.removeAll();
						MotionTarget(entity.get(MotionTarget)).targetSpatial = new Spatial(1256, 1328);
						moreNarfs = true;
					}
					else
					{
						entity.get(Narf).targetCurd = true;
						MotionTarget(entity.get(MotionTarget)).targetSpatial = spatial;
					}
				}
				else
				{
					entity.get(Narf).targetCurd = false;
					MotionTarget(entity.get(MotionTarget)).targetSpatial = _boy.get(Spatial);
				}
			}
			
			if(moreNarfs)
			{
				_cliffZone.entered.removeAll();
				SceneUtil.lockInput(this, true, true);
				CharUtils.lockControls(this.player);
				_petCreation = EntityUtils.createSpatialEntity(this, this._hitContainer["petCreation"], this._hitContainer);
				SceneUtil.addTimedEvent(this, new TimedEvent(.5, 18, narfIntoChasm));
				moveNarfWall();
			}
		}
		
		private function narfIntoChasm():void
		{
			_narfCreator.create(_petCreation, newNarfCreated);
			var group:Group = this;
			
			function newNarfCreated(entity:Entity):void
			{
				MotionTarget(entity.get(MotionTarget)).targetSpatial = new Spatial(-562, 1328);
				entity.add(new Id("pet"));
				entity.add(new Talk());
				CharUtils.assignDialog(entity, group, "pet", false, 0, 1, true);
				Dialog(entity.get(Dialog)).sayCurrent();
			}
		}
		
		private function moveNarfWall(instant:Boolean = false):void
		{
			var int2:Entity = super.getEntityById("interactive2");
			var narfWall:MovieClip = MovieClip(int2.get(Display).displayObject.getChildByName("wallOfNarfs"));
			var wallEntity:Entity = EntityUtils.createSpatialEntity(this, this.convertToBitmapSprite(narfWall).sprite);
			
			if(!instant)
			{
				wallEntity.add(new Sleep(false, true));			
				var spatial:Spatial = wallEntity.get(Spatial);
				TweenUtils.entityTo(wallEntity, Spatial, 12, {y:spatial.y - 180, ease:Quad.easeInOut, onComplete:narfWallFilled});
			}
			else
			{
				wallEntity.get(Spatial).y -= 180;
				addBlinking();
			}
		}
		
		private function narfWallFilled():void
		{
			super.shellApi.triggerEvent(_events.NARF_WALL_COMPLETE, true);
			SceneUtil.lockInput(this, false, false);
			CharUtils.lockControls(this.player, false, false);
			petFloor(true);
			Dialog(_boy.get(Dialog)).sayCurrent();
			
			for each(var narf:Entity in _pets)
			{
				super.removeEntity(narf);
			}
			
			addBlinking();
		}
		
		private function addBlinking():void
		{
			_narfEyes.alpha = 1;
			// make eyes entity
			var eyesEntity:Entity = TimelineUtils.convertAllClips(_narfEyes, eyesEntity, this, false);
			eyesEntity.add(new Id("narfEyes"));
			eyesEntity.add(new Display(_narfEyes));
			eyesEntity.add(new Spatial());
			EntityUtils.syncSpatial(eyesEntity.get(Spatial), _narfEyes);
			
			SceneUtil.addTimedEvent(this, new TimedEvent(.15, 0, Command.create(makeNarfBlink, eyesEntity)));
		}
		
		private function makeNarfBlink(entity:Entity):void
		{
			var randomInt:int = Math.ceil((Math.random() * 18));
			var randomNarf:Entity = EntityUtils.getChildById(entity, "eyes" + randomInt);
			var timeline:Timeline = randomNarf.get(Timeline);
			timeline.gotoAndPlay("blink");
		}
		
		private function petFloor(replace:Boolean = false):void
		{
			if(replace)
			{
				_petFloor.add(_bitmapHit);
			}
			else
			{
				/*********
				 * FIX: Instead of removing the whole entity, I removed and replaced just the BitmapHit component
				 ********/
				_petFloor = super.getEntityById("petFloor");
				_bitmapHit = _petFloor.get(BitmapHit);
				_petFloor.remove(BitmapHit);
			}
		}
		
		// NPCs
		private var _boy:Entity;
		private var _safetyInspector:Entity;
		
		// Interactives
		private var _dangerSign:Entity;
		private var _inspectorSign:Entity;
		private var _balloon2:Entity;
		private var _events:MocktropicaEvents;
		
		// walls
		private var _cliffZone:Zone;
		
		// Pets
		private var _narfCreator:NarfCreator;
		private var _pets:Vector.<Entity>;
		private var _petFloor:Entity;
		
		private var _bitmapHit:BitmapHit;
		
		private var _narf:Narf;
		private var _narfEyes:MovieClip;
		private var _currentCurd:Entity;	
		private var _petCreation:Entity;
	}
}